system_ruby() {
    local res='-1'
    command -v ruby > /dev/null
    if [ $? -eq 0 ]; then
        res=$(ruby -e '$stdout.write RUBY_VERSION')
    fi
    printf -- "$res"
}
