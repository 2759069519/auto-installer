#!/bin/bash
# lib/logging.sh — 安装历史记录（纯 Bash，不依赖 Python）

# ── JSON 字符串转义 ─────────────────────────────────
json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"
    echo -n "$s"
}

# ── 纯 Bash JSONL 写入 ──────────────────────────────
log_install_history() {
    local query="$1" cmd="$2" method="$3" success="$4" time_ms="${5:-0}"
    mkdir -p "$DATA_DIR"
    local ts; ts=$(date '+%Y-%m-%dT%H:%M:%S%z')

    local q_esc c_esc; q_esc=$(json_escape "$query"); c_esc=$(json_escape "$cmd")

    # 优先尝试 python3（更可靠的 JSON 序列化）
    if command -v python3 &>/dev/null; then
        python3 -c "
import json
entry = {'ts':'${ts}','query':'${q_esc}','cmd':'${c_esc}','method':'${method}','success':${success},'time_ms':${time_ms}}
with open('${HISTORY_FILE}','a') as f:
    f.write(json.dumps(entry, ensure_ascii=False) + '\n')
" 2>/dev/null && return 0
    fi

    # 纯 Bash 兜底
    echo "{\"ts\":\"${ts}\",\"query\":\"${q_esc}\",\"cmd\":\"${c_esc}\",\"method\":\"${method}\",\"success\":${success},\"time_ms\":${time_ms}}" >> "$HISTORY_FILE"
}

# ── 使用统计（纯 Bash） ─────────────────────────────
increment_stat() {
    local tool="$1"
    mkdir -p "$(dirname "$STATS_FILE")"

    if [ ! -f "$STATS_FILE" ]; then
        echo '{}' > "$STATS_FILE"
    fi

    # 优先 python3
    if command -v python3 &>/dev/null; then
        python3 -c "
import json
f='${STATS_FILE}'; t='${tool}'
try:
    d=json.load(open(f))
except: d={}
d[t]=d.get(t,0)+1
json.dump(d, open(f,'w'), indent=2, ensure_ascii=False)
" 2>/dev/null && return 0
    fi

    # 纯 Bash 兜底: 使用 grep + sed 更新计数
    if grep -q "\"${tool}\"" "$STATS_FILE" 2>/dev/null; then
        local count; count=$(grep -oP "\"${tool}\":\s*\K[0-9]+" "$STATS_FILE" 2>/dev/null || echo "0")
        count=$((count + 1))
        sed -i "s/\"${tool}\": *[0-9]*/\"${tool}\": ${count}/" "$STATS_FILE"
    else
        # 插入到最后一个 } 之前
        sed -i "s/}$/,\"${tool}\": 1}/" "$STATS_FILE"
    fi
}
