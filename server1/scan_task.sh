#!/bin/bash
FILE_OUT="bao_cao_xung_dot_task.csv"
MAX_TASK=6000
TEMP_DEFINES="defines.tmp"
TEMP_USAGE="usage.tmp"

echo "Dang lap ban do bien va kiem tra xung dot Task..."

# Quét tất cả biến có chữ Task = Số (Bao gồm cả nTask trong mảng)
grep -rnE --exclude="*.csv" --exclude="*.tmp" "\b([a-zA-Z0-9_]*[Tt][Aa][Ss][Kk][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*([0-9]+)" . | \
sed -E 's/^([^:]+):[0-9]+:.*([a-zA-Z0-9_]*[Tt][Aa][Ss][Kk][a-zA-Z0-9_]*)[[:space:]]*=[[:space:]]*([0-9]+).*/\2|\3|\1/' | sort -u > $TEMP_DEFINES

# Quét tất cả các lệnh GetTask, SetTask
grep -rnE --exclude="*.csv" --exclude="*.tmp" -o "\b(GetTask|SetTask|GetTaskBit|SetTaskBit|AddTask|HaveTask)[[:space:]]*\([[:space:]]*[a-zA-Z0-9_\[\]\.]+[^)]*\)" . | \
sed -E 's/^([^:]+):([0-9]+):(GetTask|SetTask|GetTaskBit|SetTaskBit|AddTask|HaveTask)[[:space:]]*\([[:space:]]*([a-zA-Z0-9_\[\]\.]+)([^)]*)\)/\4|\3(\4\5)|\1|\2/' > $TEMP_USAGE

# Tạo Header
echo "STT,Task ID,Trạng Thái,Biến Đang Dùng,Đường dẫn khai báo,Đường dẫn Script,Dòng" > $FILE_OUT

awk -F'|' -v max=$MAX_TASK -v output=$FILE_OUT '
# ========================================================
# BƯỚC 1: ĐỌC FILE ĐỊNH NGHĨA (TEMP_DEFINES) TRƯỚC
# Kỹ thuật NR == FNR đảm bảo bắt dính 100% mọi biến
# ========================================================
NR == FNR {
    var_name = $1
    var_val = $2 + 0
    var_file = $3
    
    local_defs[var_file SUBSEP var_name] = var_val
    global_defs[var_name] = var_val
    def_paths[var_file SUBSEP var_name] = var_file
    global_def_paths[var_name] = var_file
    
    # ÉP GHI NHẬN LUÔN CÁC ID CÓ TRONG MẢNG (VD: nTask = 2939)
    if (var_val > 0 && var_val <= max) {
        ref_name_def = var_name " (Khai báo)"
        
        if (!seen_refs[var_val SUBSEP ref_name_def]) {
            seen_refs[var_val SUBSEP ref_name_def] = 1
            count_unique_refs[var_val]++
            
            if (list_refs[var_val] == "") list_refs[var_val] = ref_name_def
            else list_refs[var_val] = list_refs[var_val] " | " ref_name_def
        }
        
        usage_key_def = var_val SUBSEP var_file SUBSEP var_file
        if (!seen_usage_in_file[usage_key_def]) {
            seen_usage_in_file[usage_key_def] = 1
            
            if (all_usage_keys[var_val] == "") all_usage_keys[var_val] = usage_key_def
            else all_usage_keys[var_val] = all_usage_keys[var_val] "@@" usage_key_def
            
            lines_in_file[usage_key_def] = "Khai báo biến/Mảng"
        }
    }
    next
}

# ========================================================
# BƯỚC 2: SAU ĐÓ ĐỌC FILE SỬ DỤNG (TEMP_USAGE) ĐỂ GOM NHÓM
# ========================================================
{
    id_or_var = $1
    func_name = $2
    file_path = $3
    line_num = $4
    
    if (id_or_var ~ /^[0-9]+$/) {
        final_id = id_or_var + 0
        ref_name = "" id_or_var ""
        decl_path = ""
    } else if (local_defs[file_path SUBSEP id_or_var]) {
        final_id = local_defs[file_path SUBSEP id_or_var]
        ref_name = "" id_or_var ""
        decl_path = def_paths[file_path SUBSEP id_or_var]
    } else if (global_defs[id_or_var]) {
        final_id = global_defs[id_or_var]
        ref_name = "" id_or_var ""
        decl_path = global_def_paths[id_or_var]
    } else {
        final_id = 0
        decl_path = ""
    }

    if (final_id > 0 && final_id <= max) {
        if (!seen_refs[final_id SUBSEP ref_name]) {
            seen_refs[final_id SUBSEP ref_name] = 1
            count_unique_refs[final_id]++
            
            if (list_refs[final_id] == "") {
                list_refs[final_id] = ref_name
            } else {
                list_refs[final_id] = list_refs[final_id] " | " ref_name
            }
        }

        usage_key = final_id SUBSEP decl_path SUBSEP file_path
        
        if (!seen_usage_in_file[usage_key]) {
            seen_usage_in_file[usage_key] = 1
            
            if (all_usage_keys[final_id] == "") {
                all_usage_keys[final_id] = usage_key
            } else {
                all_usage_keys[final_id] = all_usage_keys[final_id] "@@" usage_key
            }
            lines_in_file[usage_key] = line_num
        } else {
            lines_in_file[usage_key] = lines_in_file[usage_key] " ; " line_num
        }
    }
}
# ========================================================
# BƯỚC 3: IN BÁO CÁO 
# ========================================================
END {
    stt = 1
    for (i = 1; i <= max; i++) {
        if (all_usage_keys[i] != "") {
            if (count_unique_refs[i] > 1) {
                status = "XUNG ĐỘT"
            } else {
                status = "AN TOÀN" 
            }

            refs = list_refs[i]
            
            count = split(all_usage_keys[i], keys, "@@")
            for (j = 1; j <= count; j++) {
                k = keys[j]
                split(k, parts, SUBSEP)
                decl_p = parts[2]
                file_p = parts[3]
                lines_str = lines_in_file[k] 

                print stt "," i "," status "," refs "," decl_p "," file_p "," lines_str >> output
                stt++
            }
        } else {
            print stt "," i ",CÒN TRỐNG,,,, " >> output
            stt++
        }
    }
}' $TEMP_DEFINES $TEMP_USAGE

rm -f $TEMP_DEFINES $TEMP_USAGE
echo "HOAN THANH"