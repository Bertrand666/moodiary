use flutter_rust_bridge::frb;
use std::collections::HashMap;
use ttf_parser::{name_id, Face};

#[frb(opaque)]
pub struct FontReader;

fn read_u16_be(data: &[u8], offset: usize) -> Option<u16> {
    let end = offset.checked_add(2)?;
    let bytes = data.get(offset..end)?;
    Some(u16::from_be_bytes([bytes[0], bytes[1]]))
}

fn read_u32_be(data: &[u8], offset: usize) -> Option<u32> {
    let end = offset.checked_add(4)?;
    let bytes = data.get(offset..end)?;
    Some(u32::from_be_bytes([bytes[0], bytes[1], bytes[2], bytes[3]]))
}

fn read_i32_be(data: &[u8], offset: usize) -> Option<i32> {
    let end = offset.checked_add(4)?;
    let bytes = data.get(offset..end)?;
    Some(i32::from_be_bytes([bytes[0], bytes[1], bytes[2], bytes[3]]))
}

fn find_unicode_name(font: &Face<'_>, target_name_id: u16) -> Option<String> {
    font.names()
        .into_iter()
        .find(|name| name.name_id == target_name_id && name.is_unicode())
        .and_then(|name| name.to_string())
}

fn collect_wght_instances_from_fvar(font: &Face<'_>, wght_axis_index: usize) -> Vec<(String, f32)> {
    let mut instances = Vec::new();
    let Some(fvar_data) = font.raw_face().table(ttf_parser::Tag::from_bytes(b"fvar")) else {
        return instances;
    };

    let Some(version) = read_u32_be(fvar_data, 0) else {
        return instances;
    };
    if version != 0x0001_0000 {
        return instances;
    }

    let Some(axes_array_offset) = read_u16_be(fvar_data, 4).map(|v| v as usize) else {
        return instances;
    };
    let Some(axis_count) = read_u16_be(fvar_data, 8).map(|v| v as usize) else {
        return instances;
    };
    let Some(axis_size) = read_u16_be(fvar_data, 10).map(|v| v as usize) else {
        return instances;
    };
    let Some(instance_count) = read_u16_be(fvar_data, 12).map(|v| v as usize) else {
        return instances;
    };
    let Some(instance_size) = read_u16_be(fvar_data, 14).map(|v| v as usize) else {
        return instances;
    };

    if axis_count == 0 || instance_count == 0 || wght_axis_index >= axis_count {
        return instances;
    }

    if axis_size < 20 || instance_size < 4 + axis_count.saturating_mul(4) {
        return instances;
    }

    let Some(axis_bytes_len) = axis_count.checked_mul(axis_size) else {
        return instances;
    };
    let Some(instances_start) = axes_array_offset.checked_add(axis_bytes_len) else {
        return instances;
    };

    for index in 0..instance_count {
        let Some(record_start) = index
            .checked_mul(instance_size)
            .and_then(|v| instances_start.checked_add(v))
        else {
            break;
        };
        let Some(record_end) = record_start.checked_add(instance_size) else {
            break;
        };
        let Some(record) = fvar_data.get(record_start..record_end) else {
            break;
        };

        let Some(subfamily_name_id) = read_u16_be(record, 0) else {
            continue;
        };
        let Some(value_offset) = wght_axis_index.checked_mul(4).and_then(|v| v.checked_add(4))
        else {
            continue;
        };
        let Some(raw_value) = read_i32_be(record, value_offset) else {
            continue;
        };

        if let Some(subfamily) = find_unicode_name(font, subfamily_name_id) {
            instances.push((subfamily, raw_value as f32 / 65536.0));
        }
    }

    instances
}

impl FontReader {
    pub fn get_font_name_from_ttf(ttf_file_path: String) -> Option<String> {
        let data = match std::fs::read(ttf_file_path) {
            Ok(data) => data,
            Err(_) => return None,
        };
        let font = match Face::parse(&data, 0) {
            Ok(font) => font,
            Err(_) => return None,
        };
        font.names()
            .into_iter()
            .find(|name| name.name_id == name_id::FULL_NAME && name.is_unicode())
            .and_then(|name| name.to_string())
    }

    pub fn get_wght_axis_from_vf_font(ttf_file_path: String) -> HashMap<String, f32> {
        let mut result = HashMap::new();
        let data = match std::fs::read(ttf_file_path) {
            Ok(data) => data,
            Err(_) => return result,
        };
        let font = match Face::parse(&data, 0) {
            Ok(font) => font,
            Err(_) => return result,
        };
        let fvar = match font.tables().fvar {
            Some(fvar) => fvar,
            None => return result,
        };

        let wght_tag = ttf_parser::Tag::from_bytes(b"wght");
        if let Some((wght_axis_index, wght_axis)) = fvar
            .axes
            .into_iter()
            .enumerate()
            .find(|(_, axis)| axis.tag == wght_tag)
        {
            result.insert("default".to_string(), wght_axis.def_value);

            for (subfamily, value) in collect_wght_instances_from_fvar(&font, wght_axis_index) {
                result.insert(subfamily, value);
            }
        }

        result
    }
}
