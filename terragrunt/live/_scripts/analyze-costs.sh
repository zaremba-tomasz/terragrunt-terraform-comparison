#!/bin/bash

command -v infracost >/dev/null 2>&1 || { echo >&2 "Infracost not installed, aborting"; exit 0; }

current_stack_directory=$1
cd $current_stack_directory

stack_name="${PWD##*/}"
stack_plan_file="$stack_name.plan"
stack_plan_json_file="$stack_name.plan.json"

if [[ -f "$stack_plan_file" ]]; then
    terragrunt show -json "$stack_plan_file" > "$stack_plan_json_file"

    infracost_usage_file="$current_stack_directory/infracost/usage.yml"
    if [[ -f "$stack_plan_file" ]]; then
        infracost breakdown --path "$stack_plan_json_file" --show-skipped --usage-file "$infracost_usage_file"
    else
        infracost breakdown --path "$stack_plan_json_file" --show-skipped
    fi
else
    echo "$stack_plan_file does not exist, skipping Infracost analysis"    
fi
