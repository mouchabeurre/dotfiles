#!/usr/bin/env bash
trap ctrl_c SIGINT
ctrl_c() {
  template "${PROMPT_ERROR} {{ Italic \"Aborting\" }}"
  exit 130
}

HOARD_HOME="${XDG_CONFIG_HOME}/hoard"
TROVE_FILE="${HOARD_HOME}/trove.yml"
CONFIG_FILE="${HOARD_HOME}/config.yml"
TOKEN_START="$(yq -r '.parameter_token' "${CONFIG_FILE}")"
TOKEN_END="$(yq -r '.parameter_ending_token' "${CONFIG_FILE}")"

PROMPT_QUESTION="{{ Bold (Color \"4\" \"[?]\") }}"
PROMPT_ERROR="{{ Bold (Color \"1\" \"[!]\") }}"
template() {
  echo "${1}" | gum format -t template
}

get_namespaces() {
  local NAMESPACES="$(gum spin --show-output --title="Parsing namespaces" -- yq -r '[.commands[] | .namespace] | unique | .[]' "${TROVE_FILE}")"
  echo "${NAMESPACES}"
}
get_tags() {
  echo "$(gum spin --show-output --title="Parsing tags" -- yq -r '[.commands[] | .tags[] | select(length > 0)] | unique | .[]' "${TROVE_FILE}")"
}
get_names() {
  local NAMES="$(gum spin --show-output --title="Parsing names" -- yq -r '.commands[] | .name' "${TROVE_FILE}")"
  echo "${NAMES}"
}
get_entries() {
  local ENTRIES="$(gum spin --show-output --title="Parsing entries" -- \
    yq -r \
    '[.commands[] | "\(.name)\t\(.namespace)\t\(if .tags | length > 0 then (.tags | join(",")) else "no_tags" end)\t\(.command)\t\(.description | split("\n") | join(". "))"] | .[]' \
    "${TROVE_FILE}")"
  echo "${ENTRIES}"
}
trim_string() {
  echo "${1}"
}

find_entry() {
  declare -n RET=${1}
  local ENTRIES="$(get_entries)"
  local _RAW_ENTRY="$(printf "${ENTRIES}" | sk)"
  local SK_RET=$?
  [[ ${SK_RET} -eq 130 || -z "${_RAW_ENTRY}" ]] && template "${PROMPT_ERROR} {{ Italic \"Aborting\" }}" && exit 0
  local _NAME="$(perl -ne '/^([a-zA-Z0-9_]{2,})\s/ && print $1' <<<"${_RAW_ENTRY}")"
  local _ENTRY="$(yq -y --arg NAME "${_NAME}" '.commands | map(select(.name == $NAME))[]' "${TROVE_FILE}")"
  RET="${_ENTRY}"
}

edit_command() {
  declare -n RET=${1}
  local _COMMAND="${2}"
  template "${PROMPT_QUESTION} {{ Italic \"The\" }} {{ Italic (Underline (Color \"5\" \"command\")) }} {{ Italic \"itself\" }}:"
  _COMMAND="$(gum input \
      --placeholder="cowsay \"Strange women lying in ponds distributing ${TOKEN_START}swords${TOKEN_END} is no basis for a system of government\"" \
      --value="${_COMMAND}")"
  [[ $? -eq 130 ]] && template "${PROMPT_ERROR} {{ Italic \"Aborting\" }}" && exit 0
  _COMMAND="${_COMMAND## }"
  _COMMAND="${_COMMAND%% }"
  template "{{ Color \"5\" \"Command>\" }} ${_COMMAND}"
  if [[ ${#_COMMAND} -le 2 ]]; then
      template "${PROMPT_ERROR} {{ Italic \"Command must be longer than 2 characters\" }}" && exit 1
  fi
  tput cuu 1; tput el
  template "{{ Color \"2\" \"Command>\" }} ${_COMMAND}"
  RET="${_COMMAND}"
}
edit_name() {
  declare -n RET=${1}
  local NAMES="$(get_names)"
  local _NAME="${2}"
  while true; do
      template "${PROMPT_QUESTION} {{ Italic \"Command\" }} {{ Italic (Underline (Color \"5\" \"name\")) }}:"
      _NAME="$(gum input \
          --placeholder="set_keymap_fr" \
          --value="${_NAME}")"
      [[ $? -eq 130 ]] && template "${PROMPT_ERROR} {{ Italic \"Aborting\" }}" && exit 0
      _NAME="$(trim_string ${_NAME})"
      template "{{ Color \"5\" \"Name>\" }} ${_NAME}"
      if LANG=C.UTF-8 && [[ ! "${_NAME}" =~ ^[a-zA-Z0-9_]{2,}$ ]]; then
          template "${PROMPT_ERROR} {{ Italic \"This name contains invalid characters\" }}"
      elif [[ -z "${2}" ]] && rg -q "(${_NAME})" <(printf "${NAMES}"); then
          template "${PROMPT_ERROR} {{ Italic \"This name is already taken\" }}"
      else
          tput cuu 1; tput el
          template "{{ Color \"2\" \"Name>\" }} ${_NAME}"
          break
      fi
  done
  RET="${_NAME}"
}
edit_namespace() {
  declare -n RET=${1}
  local NAMESPACES="$(get_namespaces)"
  local _NAMESPACE="${2}"
  while true; do
    template "${PROMPT_QUESTION} {{ Italic \"Command\" }} {{ Italic (Underline (Color \"5\" \"namespace\")) }}:"
    _NAMESPACE="$(printf "${NAMESPACES}" | sk --exact --print-query --query="${_NAMESPACE}")"
    local SK_RET=$?
    [[ ${SK_RET} -eq 130 ]] && template "${PROMPT_ERROR} {{ Italic \"Aborting\" }}" && exit 0
    _NAMESPACE="$(tail -n 1 <<<"${_NAMESPACE}")"
    template "{{ Color \"5\" \"Namespace>\" }} ${_NAMESPACE}"
    if LANG=C.UTF-8 && [[ ! "${_NAMESPACE}" =~ ^[a-zA-Z0-9_\ ]{2,}$ ]]; then
      template "${PROMPT_ERROR} {{ Italic \"This namespace contains invalid characters\" }}"
    else
      tput cuu 1; tput el
      template "{{ Color \"2\" \"Namespace>\" }} ${_NAMESPACE}"
      break
    fi
  done
  RET="${_NAMESPACE}"
}
edit_description() {
  declare -n RET=${1}
  template "${PROMPT_QUESTION} {{ Italic \"Command\" }} {{ Italic (Underline (Color \"5\" \"description\")) }}:"
  local _DESCRIPTION="${2}"
  _DESCRIPTION="$(gum write \
    --placeholder="Description of the command" \
    --value="${_DESCRIPTION}")"
  [[ $? -eq 130 ]] && template "${PROMPT_ERROR} {{ Italic \"Aborting\" }}" && exit 0
  template "{{ Color \"2\" \"Description>\" }} ---"
  echo "${_DESCRIPTION}"
  template "{{ Color \"2\" \"Description>\" }} ---"
  RET="${_DESCRIPTION}"
}
edit_tags() {
  declare -n RET=${1}
  local ALL_TAGS="$(get_tags)"
  local _TAGS="${2}"
  local _FIRST_ITER=1
  local _ERRORED=0
  while true; do
    # clear previous log iteration
    if [[ ${_FIRST_ITER} -eq 1 ]]; then
      _FIRST_ITER=0
    else
      local _LOG_LINES=$((_ERRORED + $(wc -l <<<"${_TAGS}") + 3))
      tput cuu ${_LOG_LINES}; tput ed
    fi
    _ERRORED=0
    template "${PROMPT_QUESTION} {{ Italic \"Command\" }} {{ Italic (Underline (Color \"5\" \"tags\")) }}:"
    _TAGS="$(printf "${ALL_TAGS}\nnotag" | uniq | sk --multi --exact --print-query --pre-select-items="${_TAGS}")"
    local SK_RET=$?
    [[ ${SK_RET} -eq 130 ]] && template "${PROMPT_ERROR} {{ Italic \"Aborting\" }}" && exit 0
    local NEW_TAG="$(head -n 1 <<<"${_TAGS}")"
    if [[ -n "${NEW_TAG}" ]]; then
      if LANG=C.UTF-8 && [[ ! "${NEW_TAG}" =~ ^[a-zA-Z0-9_\ ]{2,}$ ]]; then
        template "${PROMPT_ERROR} {{ Italic \"New tag\" }} {{ Bold \"${NEW_TAG}\" }} {{ Italic \"contains invalid characters\" }}"
        _ERRORED=1
        _TAGS="$(sed '1d' <<<"${_TAGS}")"
        continue
      else
        ALL_TAGS="${ALL_TAGS}\n${NEW_TAG}"
      fi
    else
      _TAGS="$(sed '1d' <<<"${_TAGS}")"
    fi
    template "{{ Color \"2\" \"Tags> ---\" }}"
    echo "${_TAGS}"
    template "{{ Color \"2\" \"Tags> ---\" }}"
    gum confirm "Continue editing tags?"
    local CONFIRM_RET=$?
    [[ ${CONFIRM_RET} -eq 130 ]] && template "${PROMPT_ERROR} {{ Italic \"Aborting\" }}" && exit 0
    if [[ ${CONFIRM_RET} -eq 1 ]]; then
      break
    fi
  done
  RET="${_TAGS}"
}
build_entry() {
  declare -n RET=${1}
  local COMMAND="${2}"
  local NAME="${3}"
  local NAMESPACE="${4}"
  local DESCRIPTION="${5}"
  local TAGS="${6}"

  local _ENTRY="$(cat <<EOF
- name: ${NAME}
  command: $(perl -pe "s/'/\\\'/g" <<<"${COMMAND}")
  namespace: ${NAMESPACE}
  tags:
$(while read TAG; do printf "    - %s\n" "${TAG}"; done <<<"${TAGS}")
  description: |-
$(while read LINE; do printf "    %s\n" "${LINE}"; done <<<"${DESCRIPTION}")
EOF
  )"
  RET="${_ENTRY}"
}
confirm_entry() {
  declare -n RET=${1}
  local ENTRY="${2}"
  template "{{ Color \"2\" \"Entry> ---\" }}"
  printf "%s" "${ENTRY}" | bat -p -l YAML
  template "{{ Color \"2\" \"Entry> ---\" }}"
  gum confirm "Persist entry?"
  local CONFIRM_RET=$?
  [[ ${CONFIRM_RET} -eq 130 ]] && template "${PROMPT_ERROR} {{ Italic \"Aborting\" }}" && exit 0
  if [[ ${CONFIRM_RET} -eq 0 ]]; then
    RET=1
  else
    RET=0
  fi
}

add_entry() {
  local COMMAND
  local NAME
  local NAMESPACE
  local DESCRIPTION
  local TAGS
  local ENTRY
  local CONFIRM
  edit_command COMMAND
  edit_name NAME
  edit_namespace NAMESPACE
  edit_description DESCRIPTION
  edit_tags TAGS
  build_entry ENTRY "${COMMAND}" "${NAME}" "${NAMESPACE}" "${DESCRIPTION}" "${TAGS}"
  confirm_entry CONFIRM "${ENTRY}"
  if [[ ${CONFIRM} -eq 1 ]]; then
    yq -y '' <<<"${ENTRY}" | perl -pe 's/^(.*)/  $1/g' >> "${TROVE_FILE}"
  else
    gum confirm "Edit entry?"
    local CONFIRM_RET=$?
    [[ ${CONFIRM_RET} -eq 130 ]] && template "${PROMPT_ERROR} {{ Italic \"Aborting\" }}" && exit 0
    if [[ ${CONFIRM_RET} -eq 0 ]]; then
      edit_entry "${ENTRY}"
    fi
  fi
}
edit_entry() {
  local EDITING=1
  local ENTRY="${1}"
  local ORIG_ENTRY_NAME
  while true; do
    if [[ -z "${ENTRY}" ]]; then
      find_entry ENTRY
      ORIG_ENTRY_NAME="$(yq -r '.name' <<<"${ENTRY}")"
    else
      ENTRY="$(yq -y '.[0]' <<<"${ENTRY}")"
    fi
    template "{{ Color \"2\" \"Entry> ---\" }}"
    printf "%s" "${ENTRY}" | bat -p -l YAML
    template "{{ Color \"2\" \"Entry> ---\" }}"
    local COMMAND="$(yq -r '.command' <<<"${ENTRY}")"
    local NAME="$(yq -r '.name' <<<"${ENTRY}")"
    local NAMESPACE="$(yq -r '.namespace' <<<"${ENTRY}")"
    local DESCRIPTION="$(yq -r '.description' <<<"${ENTRY}")"
    local TAGS="$(yq -r 'if .tags | length > 0 then .tags[] else empty end' <<<"${ENTRY}")"
    local NEW_COMMAND
    local NEW_NAME
    local NEW_NAMESPACE
    local NEW_DESCRIPTION
    local NEW_TAGS
    local CONFIRM
    edit_command NEW_COMMAND "${COMMAND}"
    edit_name NEW_NAME "${NAME}"
    edit_namespace NEW_NAMESPACE "${NAMESPACE}"
    edit_description NEW_DESCRIPTION "${DESCRIPTION}"
    edit_tags NEW_TAGS "${TAGS}"
    build_entry ENTRY "${NEW_COMMAND}" "${NEW_NAME}" "${NEW_NAMESPACE}" "${NEW_DESCRIPTION}" "${NEW_TAGS}"
    confirm_entry CONFIRM "${ENTRY}"
    if [[ ${CONFIRM} -eq 1 ]]; then
      if [[ -z "${1}" ]]; then
        # delete old entry
        yq -y --arg NAME "${ORIG_ENTRY_NAME}" 'del(.commands[] | select(.name == $NAME))' "${TROVE_FILE}" | sponge "${TROVE_FILE}"
      fi
      yq -y '' <<<"${ENTRY}" | perl -pe 's/^(.*)/  $1/g' >> "${TROVE_FILE}"
      break
    fi
  done
}
delete_entry() {
  local ENTRY
  find_entry ENTRY
  local NAME="$(yq -r '.name' <<<"${ENTRY}")"
  template "{{ Color \"2\" \"Entry> ---\" }}"
  printf "%s" "${ENTRY}" | bat -p -l YAML
  template "{{ Color \"2\" \"Entry> ---\" }}"
  gum confirm "Delete entry?"
  local CONFIRM_RET=$?
  [[ ${CONFIRM_RET} -eq 130 ]] && template "${PROMPT_ERROR} {{ Italic \"Aborting\" }}" && exit 0
  if [[ ${CONFIRM_RET} -eq 0 ]]; then
    yq -y --arg NAME "${NAME}" 'del(.commands[] | select(.name == $NAME))' "${TROVE_FILE}" | sponge "${TROVE_FILE}"
  fi
}
prompt_action() {
  local CHOICE_ADD="Add"
  local CHOICE_EDIT="Edit"
  local CHOICE_DEL="Delete"
  template "${PROMPT_QUESTION} {{ Italic \"Trove\" }} {{ Italic (Underline (Color \"5\" \"action\")) }}:"
  local ACTION=$(printf "${CHOICE_ADD}\n${CHOICE_EDIT}\n${CHOICE_DEL}" | sk)
  [[ -z "${ACTION}" ]] && template "${PROMPT_ERROR} {{ Italic \"Aborting\" }}" && exit 0
  template "{{ Color \"2\" \"Action>\" }} ${ACTION}"
  if [[ "${ACTION}" == "${CHOICE_ADD}" ]]; then
    add_entry
  elif [[ "${ACTION}" == "${CHOICE_EDIT}" ]]; then
    edit_entry
  elif [[ "${ACTION}" == "${CHOICE_DEL}" ]]; then
    delete_entry
  fi
}

prompt_action
