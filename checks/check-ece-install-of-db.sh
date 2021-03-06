#! /usr/bin/env bash

check_ece_install_have_installed_db_files() {
  local -a files=(
    /usr/bin/mysql
    /usr/bin/mysqld_safe
    /usr/bin/mysqld_multi
  )

  for file in "${files[@]}"; do
    ((number_of_tests++))
    test -e "${file}" || {
      flag_error "Should have created ${file}"
    }

    if [ "${verbose-0}" -eq 1 ]; then
      echo "File exists as expected: ${file}"
    else
      echo -n "."
    fi
  done
}

_run_sql_mysql() {
  local sql=$1

  mysql \
    -u "${ece_db_user}" \
    -p"${ece_db_password}" "${ece_db_schema}" \
    -e "${sql}" &> /dev/null
}

check_ece_install_have_set_up_ece_db_tables() {
  if [[ -z "${ece_db_user}" ||
          -z "${ece_db_password}" ||
          -z "${ece_db_schema}" ]]; then
    return
  fi
  local sql='
      select count(contentID) from Content;
    '
  _run_sql_mysql "${sql}" || {
    flag_error "Should have set up DB with schema ${ece_db_schema} on ${HOSTNAME}"
  }
}

check_ece_install_have_set_up_plugin_db_tables() {
  if [[ -z "${ece_db_user}" ||
          -z "${ece_db_password}" ||
          -z "${ece_db_schema}" ]]; then
    return
  fi

  for plugin_dir in $(find /usr/share/escenic -name "escenic-*" -type d); do
    local plugin_tables_sql="${plugin_dir}/misc/database/mysql/tables.sql"

    if [ ! -r "${plugin_tables_sql}" ]; then
      continue
    fi

    local plugin=${plugin_dir##/usr/share/escenic/escenic-}

    for table in $(grep -i "create table" "${plugin_tables_sql}" | awk '{print $3}'); do
      _run_sql_mysql "describe ${table}" || {
        flag_error "Table ${table} from plugin ${plugin} should be present" \
                   "in schema ${ece_db_schema} on ${HOSTNAME}"
      }
    done
  done
}
