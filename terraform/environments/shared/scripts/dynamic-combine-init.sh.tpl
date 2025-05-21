#!/bin/bash
exec > >(tee /var/log/user-data-combined.log) 2>&1
echo "### [START] Dynamic Combined UserData Script - $(date)"

# 기본 초기화 스크립트 (항상 실행)
${base_script}

# 동적으로 선택된 스크립트들 실행
%{ for script_name, script_content in scripts }
# --- Begin Script: ${script_name} ---
echo "### [EXECUTING] Script: ${script_name} - $(date)"
${script_content}
echo "### [COMPLETED] Script: ${script_name} - $(date)"
# --- End Script: ${script_name} ---

%{ endfor }

echo "### [COMPLETED] Dynamic Combined UserData Script - $(date)"