#!/bin/bash
#
# Copyright 2020 Gravitational, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
set -o errexit
set -o errtrace
set -o pipefail

year=$1
set -o nounset

if [ -z "$year" ]; then
    echo "$0: please specify the current year as the first argument"
    exit 2
fi

# exit_code is used to determine the exit code at the end
exit_code=0

notice() {
    local file="$1"
    local diff="$2"
    echo "Incorrect copyright notice in ${file}"
    echo "${diff}"
    exit_code=1
}

gitfiles=$(git ls-files)

gofiles=$(echo "${gitfiles}" | grep '\.go$')
shfiles=$(echo "${gitfiles}" | grep '\.sh$')
makefiles=$(echo "${gitfiles}" | grep 'Makefile$')
dockerfiles=$(echo "${gitfiles}" | grep 'Dockerfile$')

# Golang files
################################################################################
expected=$(cat<<EOF
/*
Copyright ${year} Gravitational, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
x
EOF
);

# the trailing 'x'and this line are to work around bash feature that
# strips trailing newlines during assignment
# see https://stackoverflow.com/questions/15184358
#
# We want to validate a trailing newline, because otherwise go doc
# will pick up the license header as part of the module documentation
expected=${expected%x}


len=$(wc -l <(echo "$expected") | cut -f1 -d ' ')
for f in ${gofiles}
do
    set +o errexit
    diff=$(diff <(head -$len $f) <(echo "$expected"))
    rc=$?
    set -o errexit
    if [ $rc -ne 0 ]
    then
        notice "$f" "$diff"
    fi
done

# Shell-like files (use # for comments, but no shebang)
################################################################################
expected=$(cat<<EOF
# Copyright ${year} Gravitational, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
EOF
)
len=$(wc -l <(echo "$expected") | cut -f1 -d ' ')
for f in ${makefiles} ${dockerfiles}
do
    set +o errexit
    diff=$(diff <(head -$len $f) <(echo "$expected"))
    rc=$?
    set -o errexit
    if [ $rc -ne 0 ]
    then
        notice "$f" "$diff"
    fi
done

# Shell files (use # for comments first line must be shebang)
################################################################################
expected=$(cat<<EOF
#
# Copyright ${year} Gravitational, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
EOF
)

len=$(wc -l <(echo "$expected") | cut -f1 -d ' ')
for f in ${shfiles}
do
    set +o errexit
    found=$(head -$(($len + 1)) $f | tail -$len) # exclude the shebang line
    diff=$(diff <(echo "$found") <(echo "$expected"))
    rc=$?
    set -o errexit
    if [ $rc -ne 0 ]
    then
        notice "$f" "$diff"
    fi
done

exit $exit_code
