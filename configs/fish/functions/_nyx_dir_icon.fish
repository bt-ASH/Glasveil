function _nyx_dir_icon --description "按 starship 的检测规则返回当前目录的工程图标+版本；没有则输出空"
    # 条件对齐本机 starship（即 fish0，实测得出），图标取自 starship.toml 第 62~136 行：
    #   docker U+F308   rust U+E68B   node U+E718   python U+E606
    #   conda  U+F10C   java U+E66D   c    U+E61E
    # 版本号来自工具链（见 _nyx_ver），显示格式对齐用户 starship.toml 的 version_format = "${raw}"。
    # 本函数只输出“工程图标[+版本]”；git（分支）与默认文件夹由调用方 fish_prompt 处理。
    # 多个条件同时命中时按下面顺序取第一个。

    set -l icon
    set -l vtype

    # ★ 唯一偏离 starship 的一条：实测 docker_context 即使有 Dockerfile 也不触发，
    #   但按你之前的要求保留 Dockerfile/compose → docker 图标。想严格对齐就删掉这个 if 段。
    if test -e Dockerfile; or test -e compose.yml; or test -e compose.yaml; or test -e docker-compose.yml; or test -e docker-compose.yaml
        set icon (printf '\uf308'); set vtype docker
    end

    if test -z "$icon"
        set -l e (command ls -A 2>/dev/null)
        set -l ext
        for x in $e
            set ext $ext (string replace -r '^.*\.' '' -- $x)
        end

        # rust：Cargo.toml 或 *.rs
        if test -e Cargo.toml; or contains -- rs $ext
            set icon (printf '\ue68b'); set vtype rust

        # nodejs：package.json / .node-version / .nvmrc / node_modules / js·ts 系列扩展名
        else if test -e package.json; or test -e .node-version; or test -e .nvmrc; or test -d node_modules
            set icon (printf '\ue718'); set vtype nodejs
        else if contains -- js $ext; or contains -- mjs $ext; or contains -- cjs $ext; or contains -- ts $ext; or contains -- mts $ext; or contains -- cts $ext
            set icon (printf '\ue718'); set vtype nodejs

        # python：__init__.py / tox.ini / .python-version / Pipfile / requirements.txt / pyproject.toml / setup.py / *.py
        else if test -e __init__.py; or test -e tox.ini; or test -e .python-version; or test -e Pipfile; or test -e requirements.txt; or test -e pyproject.toml; or test -e setup.py
            set icon (printf '\ue606'); set vtype python
        else if contains -- py $ext
            set icon (printf '\ue606'); set vtype python

        # conda：environment.yml / conda-meta（starship 其实是按 $CONDA_DEFAULT_ENV）
        else if test -e environment.yml; or test -d conda-meta
            set icon (printf '\uf10c'); set vtype conda

        # java：pom.xml / build.gradle[.kts] / build.sbt / .java-version / deps.edn / project.clj / build.boot / .sdkmanrc
        else if test -e pom.xml; or test -e build.gradle; or test -e build.gradle.kts; or test -e build.sbt; or test -e .java-version; or test -e deps.edn; or test -e project.clj; or test -e build.boot; or test -e .sdkmanrc
            set icon (printf '\ue66d'); set vtype java
        else if contains -- java $ext; or contains -- class $ext; or contains -- gradle $ext; or contains -- jar $ext; or contains -- clj $ext; or contains -- cljc $ext; or contains -- cljs $ext
            set icon (printf '\ue66d'); set vtype java

        # c：*.c / *.h（starship 不认 Makefile / CMakeLists.txt）
        else if contains -- c $ext; or contains -- h $ext
            set icon (printf '\ue61e'); set vtype c
        end
    end

    test -z "$icon"; and return

    set -l v
    test -n "$vtype"; and set v (_nyx_ver $vtype)
    if test -n "$v"
        printf '%s %s' $icon $v
    else
        printf '%s' $icon
    end
end
