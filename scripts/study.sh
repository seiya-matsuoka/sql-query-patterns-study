#!/usr/bin/env bash
set -euo pipefail

project_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd -- "$project_root"

usage() {
    cat <<'USAGE'
使い方: bash scripts/study.sh start
        bash scripts/study.sh reset-data
        bash scripts/study.sh run <sql/配下のSQLファイル>
        bash scripts/study.sh verify [sql/配下のSQLファイル]
        bash scripts/study.sh stop
USAGE
}

fail() {
    printf '%s\n' "$*" >&2
    exit 1
}

invalid_arguments() {
    usage >&2
    exit 2
}

compose() {
    # 環境変数で別の Compose プロジェクトが選ばれないよう、名前と設定ファイルを指定する。
    docker compose --project-name sql-query-patterns-study --file compose.yaml --env-file .env "$@"
}

psql_in_db() {
    local read_only=$1
    shift

    # ホストの SQL パスは渡さず、標準入力からコンテナ内の psql へ送る。
    # -X で psqlrc の影響を避け、SQL エラーを終了状態に反映する。
    # run と verify では通常の書き込みを防ぐため、読み取り専用を既定にする。
    compose exec -T \
        -e "PGOPTIONS=-c default_transaction_read_only=$read_only" \
        -e PGCLIENTENCODING=UTF8 db \
        sh -c 'exec psql -X -w --username="$POSTGRES_USER" --dbname="$POSTGRES_DB" --set=ON_ERROR_STOP=1 --pset=pager=off "$@" --file=-' \
        psql "$@"
}

lesson_path() {
    local absolute_path
    [[ -f $1 ]] || fail "教材 SQL が見つからない: $1"
    absolute_path=$(realpath -- "$1")

    # 教材と期待 CSV の対応付けに使うため、実体が sql/ 内にあるファイルを基準にする。
    [[ $absolute_path == "$project_root"/sql/*.sql ]] || fail "sql/ 配下の SQL ファイルを指定する: $1"
    printf '%s\n' "${absolute_path#"$project_root"/}"
}

split_examples() {
    local file=$1 work_dir=$2

    # 予約した識別子行で区切り、その後の SQL を改変せずに渡す。
    # セミコロンでは分割しない。識別子ごとに 1 問い合わせとする規約を教材側で守る。
    LC_ALL=C awk -v dir="$work_dir" '
        function fail(message) {
            print FILENAME ":" FNR ": " message > "/dev/stderr"
            failed = 1
            exit 1
        }
        /^[[:space:]]*--[[:space:]]*example:/ {
            if ($0 !~ /^-- example: [a-z][a-z0-9-]*$/) {
                fail("Use -- example: <lowercase-id> at the start of a line.")
            }
            id = substr($0, length("-- example: ") + 1)
            if (seen[id]++) {
                fail("Duplicate example: " id)
            }
            if (file != "") {
                close(file)
            }
            file = dir "/" id ".sql"
            print id
            print $0 > file
            next
        }
        file != "" {
            print $0 > file
            next
        }
        !/^[[:space:]]*(--.*)?$/ {
            fail("SQL found before the first example marker.")
        }
        END {
            if (!failed && file == "") {
                fail("No example markers found.")
            }
        }
    ' "$file" >"$work_dir/examples.txt"
}

verify_lesson() {
    local file=$1 work_dir=$2 id expected_dir expected_csv
    expected_dir="expected/${file#sql/}"
    expected_dir=${expected_dir%.sql}
    split_examples "$file" "$work_dir"

    while IFS= read -r id; do
        expected_csv="$expected_dir/$id.csv"
        [[ -s $expected_csv ]] || fail "期待 CSV がないか空である: $expected_csv"

        if ! psql_in_db on --csv --quiet --pset='null=<NULL>' \
            <"$work_dir/$id.sql" >"$work_dir/actual.csv"; then
            fail "実行に失敗した: $file ($id)"
        fi
        [[ -s $work_dir/actual.csv ]] || fail "結果 CSV が出力されなかった: $file ($id)"

        # ヘッダーを含む CSV をそのまま比較する。0 行、重複、行順を差として扱う。
        if ! diff -u --label "$expected_csv" --label "実行結果 ($file / $id)" \
            -- "$expected_csv" "$work_dir/actual.csv"; then
            fail "期待結果との照合に失敗した: $file ($id)"
        fi
        printf '照合成功: %s (%s)\n' "$file" "$id"
    done <"$work_dir/examples.txt"
}

verify_lessons() (
    work_dir=$(mktemp -d ./.study-verify.XXXXXX)
    # 今回生成したファイルだけを取り除き、教材と期待 CSV は読み取りだけにする。
    trap 'rm -f -- "$work_dir"/*.sql "$work_dir"/actual.csv "$work_dir"/examples.txt "$work_dir"/files.list; rmdir -- "$work_dir"' EXIT

    if (($# == 1)); then
        file=$(lesson_path "$1")
        verify_lesson "$file" "$work_dir"
    else
        # ファイルを処理する順だけを固定し、問い合わせ結果の行順は変更しない。
        find sql -type f -name '*.sql' -print0 | LC_ALL=C sort -z >"$work_dir/files.list"
        [[ -s $work_dir/files.list ]] || fail "検証対象の教材がない"
        while IFS= read -r -d '' file; do
            verify_lesson "$file" "$work_dir"
        done <"$work_dir/files.list"
    fi
)

case "${1:-}" in
start | reset-data | stop) (($# == 1)) || invalid_arguments ;;
run) (($# == 2)) || invalid_arguments ;;
verify) (($# <= 2)) || invalid_arguments ;;
-h | --help)
    usage
    exit 0
    ;;
*) invalid_arguments ;;
esac

[[ -f .env ]] || fail ".env.example を .env にコピーし、学習用 DB のパスワードを設定する"

case "$1" in
start) compose up --detach --wait --wait-timeout 60 db ;;
reset-data)
    psql_in_db off --quiet <data/reset.sql
    printf '学習用データを再構築した\n'
    ;;
run)
    file=$(lesson_path "$2")
    psql_in_db on --pset='null=<NULL>' <"$file"
    ;;
verify)
    shift
    verify_lessons "$@"
    ;;
stop) compose stop db ;;
esac
