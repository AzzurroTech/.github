#!/bin/bash
# go-check.sh — Comprehensive Go project scanner
# Finds modules, orphans, multi-package dirs, unused deps
# Runs vet/fmt/staticcheck/build/tidy on each module
# Aggregates all issues into a single issues.log

PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd -P)"
RESULTS_DIR="${PROJECT_ROOT}/.lint-results"
mkdir -p "${RESULTS_DIR}"
rm -f "${RESULTS_DIR}"/*.log 2>/dev/null || true

VERBOSE_LOG="${RESULTS_DIR}/verbose.log"
ISSUES_LOG="${RESULTS_DIR}/issues.log"
ORPHANS_LOG="${RESULTS_DIR}/orphans.log"
SUGGESTIONS_LOG="${RESULTS_DIR}/module-suggestions.log"
MULTIPKG_LOG="${RESULTS_DIR}/multi-package.log"
DEPS_LOG="${RESULTS_DIR}/dependency-analysis.log"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Counters
TOTAL_PROBLEMS=0
TOTAL_MODULES=0
TOTAL_FILES=0
TOTAL_ORPHAN_FILES=0
TOTAL_MISSING_DEPS=0
TOTAL_SUGGESTED_MODULES=0
TOTAL_MULTIPKG_DIRS=0
TOTAL_UNUSED_DEPS=0
TOTAL_EXTERNAL_DEPS=0
TOTAL_LOCAL_DEPS=0
TOTAL_VET_ISSUES=0
TOTAL_FMT_ISSUES=0
TOTAL_STATIC_ISSUES=0
TOTAL_BUILD_ISSUES=0
TOTAL_TIDY_ISSUES=0

STDLIB_PREFIXES=("bufio" "bytes" "compress" "context" "crypto" "encoding" "errors" "flag" "fmt" "go" "google.golang.org/protobuf" "hash" "html" "image" "io" "log" "math" "mime" "net" "os" "path" "reflect" "regexp" "runtime" "sort" "strconv" "strings" "sync" "syscall" "testing" "time" "unicode" "unsafe")

is_stdlib() {
    local pkg="$1"
    for prefix in "${STDLIB_PREFIXES[@]}"; do
        [[ "${pkg}" == "${prefix}"* ]] && return 0
    done
    [[ ! "${pkg}" =~ \. && "${pkg}" != "google.golang.org/protobuf"* ]] && return 0
    return 1
}

# Initialize all logs
{
    echo "========================================================"
    echo "GO CHECK VERBOSE LOG"
    echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "Project root: ${PROJECT_ROOT}"
    echo "========================================================"
    echo ""
    echo "[STEP 1] Finding existing go.mod files..."
} > "${VERBOSE_LOG}"

{
    echo "========================================================"
    echo "AGGREGATED ISSUES FROM ALL TOOLS"
    echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "Project root: ${PROJECT_ROOT}"
    echo "========================================================"
    echo ""
} > "${ISSUES_LOG}"

echo -e "${GREEN}Scanning for Go modules and files...${NC}"
echo "Project root: ${PROJECT_ROOT}"
echo ""

# ── STEP 1: Collect existing go.mod locations ──
declare -A MODULE_DIRS
declare -a MODULE_PATHS_ARRAY

echo -e "${CYAN}[Step 1] Finding existing go.mod files...${NC}"
while IFS= read -r modfile; do
    MOD_DIR="$(dirname "${modfile}")"
    MODULE_DIRS["${MOD_DIR}"]=1
    MODULE_PATHS_ARRAY+=("${MOD_DIR}")
    REL="${MOD_DIR#${PROJECT_ROOT}/}"
    [[ "${REL}" == "." ]] && REL="(root)"
    echo "  Existing: ${REL}"
    echo "  [STEP 1] Found module: ${REL}" >> "${VERBOSE_LOG}"
done < <(find "${PROJECT_ROOT}" -name "go.mod" -type f -not -path "*/.git/*" -not -path "*/vendor/*" | sort)
echo "" >> "${VERBOSE_LOG}"
echo "[STEP 1] Complete. Found ${#MODULE_PATHS_ARRAY[@]} module(s)." >> "${VERBOSE_LOG}"
echo ""

# ── STEP 2: Find ALL Go files and categorize ──
echo -e "${CYAN}[Step 2] Finding all Go files...${NC}"
echo "[STEP 2] Finding all .go files..." >> "${VERBOSE_LOG}"

ALL_GO_FILES=()
ORPHAN_GO_FILES=()

while IFS= read -r gofile; do
    GO_DIR="$(dirname "${gofile}")"
    PARENT_DIR="${GO_DIR}"
    IN_MODULE=false
    
    while [[ "${PARENT_DIR}" != "${PROJECT_ROOT}" && "${PARENT_DIR}" != "/" ]]; do
        [[ -f "${PARENT_DIR}/go.mod" ]] && IN_MODULE=true && break
        PARENT_DIR="$(dirname "${PARENT_DIR}")"
    done
    
    [[ -f "${PROJECT_ROOT}/go.mod" ]] && IN_MODULE=true
    
    if [[ "${IN_MODULE}" == "true" ]]; then
        ALL_GO_FILES+=("${gofile}")
    else
        ORPHAN_GO_FILES+=("${gofile}")
        ((TOTAL_ORPHAN_FILES++)) || true
    fi
done < <(find "${PROJECT_ROOT}" -name "*.go" -type f -not -path "*/.git/*" -not -path "*/vendor/*" | sort)

TOTAL_FILES=${#ALL_GO_FILES[@]}
echo "  In modules: ${TOTAL_FILES} files"
echo "  Orphaned (outside any module): ${TOTAL_ORPHAN_FILES} files"
echo "[STEP 2] Files in modules: ${TOTAL_FILES}, Orphaned: ${TOTAL_ORPHAN_FILES}" >> "${VERBOSE_LOG}"
echo ""

if [[ ${TOTAL_ORPHAN_FILES} -gt 0 ]]; then
    {
        echo "========================================================"
        echo "ORPHANED GO FILES"
        echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo "========================================================"
        echo ""
        echo "Orphaned Go files (not in any module):"
        printf '%s\n' "${ORPHAN_GO_FILES[@]}" | sed 's/^/  /'
        echo ""
    } > "${ORPHANS_LOG}"
fi

# ── STEP 3: Suggest module placements ──
echo -e "${CYAN}[Step 3] Analyzing orphaned files for module suggestions...${NC}"
echo "[STEP 3] Analyzing orphaned files..." >> "${VERBOSE_LOG}"

declare -A ORPHAN_GROUPS
for orphan in "${ORPHAN_GO_FILES[@]}"; do
    REL_PATH="${orphan#${PROJECT_ROOT}/}"
    TOP_DIR="$(echo "${REL_PATH}" | cut -d'/' -f1)"
    if [[ -n "${TOP_DIR}" && ! "${MODULE_DIRS[*]:-}" =~ "${PROJECT_ROOT}/${TOP_DIR}" ]]; then
        ORPHAN_GROUPS["${TOP_DIR}"]="${ORPHAN_GROUPS[${TOP_DIR}]:-} ${orphan}"
    fi
done

{
    echo "========================================================"
    echo "MODULE ORGANIZATION SUGGESTIONS"
    echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "========================================================"
    echo ""
} > "${SUGGESTIONS_LOG}"

for top_dir in "${!ORPHAN_GROUPS[@]}"; do
    ((TOTAL_SUGGESTED_MODULES++)) || true
    FILES_IN_DIR="${ORPHAN_GROUPS[${top_dir}]}"
    FILE_LIST=(${FILES_IN_DIR})
    FILE_COUNT=${#FILE_LIST[@]}
    SUGGESTION_DIR="${PROJECT_ROOT}/${top_dir}"
    
    echo -e "${YELLOW}  Top-level: ${top_dir}/${NC}"
    echo -e "${YELLOW}  Suggested go.mod location: ${SUGGESTION_DIR#${PROJECT_ROOT}/}${NC}"
    echo -e "${YELLOW}  Files to include: ${FILE_COUNT}${NC}"
    
    {
        echo "========================================"
        echo "SUGGESTED MODULE: ${top_dir}"
        echo "Proposed go.mod: ${SUGGESTION_DIR}/go.mod"
        echo "Files (${FILE_COUNT}):"
        for f in "${FILE_LIST[@]}"; do
            echo "  - ${f#${PROJECT_ROOT}/}"
        done
        echo ""
        echo "Commands to initialize:"
        echo "  cd ${SUGGESTION_DIR}"
        echo "  go mod init ${top_dir}"
        echo "  go mod tidy"
        echo ""
    } >> "${SUGGESTIONS_LOG}"
    echo "  [STEP 3] Suggested module: ${top_dir}" >> "${VERBOSE_LOG}"
    echo ""
done

[[ ${TOTAL_SUGGESTED_MODULES} -eq 0 ]] && echo "All Go files already belong to modules" >> "${SUGGESTIONS_LOG}"
echo "[STEP 3] Complete. Suggested ${TOTAL_SUGGESTED_MODULES} new module(s)." >> "${VERBOSE_LOG}"
echo ""

# ── STEP 4: Detect multiple packages in same directory ──
echo -e "${CYAN}[Step 4] Checking for multiple packages in same directory...${NC}"
echo "[STEP 4] Checking for multiple packages..." >> "${VERBOSE_LOG}"

declare -A DIR_PACKAGES
declare -A DIR_FILES

while IFS= read -r gofile; do
    GO_DIR="$(dirname "${gofile}")"
    PKG_NAME="$(head -50 "${gofile}" | grep -m1 -E "^package " | awk '{print $2}')"
    if [[ -n "${PKG_NAME}" ]]; then
        DIR_PACKAGES["${GO_DIR}"]="${DIR_PACKAGES[${GO_DIR}]:-} ${PKG_NAME}"
        DIR_FILES["${GO_DIR}"]="${DIR_FILES[${GO_DIR}]:-} ${gofile}|${PKG_NAME}"
    fi
done < <(find "${PROJECT_ROOT}" -name "*.go" -type f -not -path "*/.git/*" -not -path "*/vendor/*" | sort)

MULTIPKG_DETAILS=""

for dir in "${!DIR_PACKAGES[@]}"; do
    UNIQUE_PKGS=($(echo "${DIR_PACKAGES[${dir}]}" | tr ' ' '\n' | sort -u | grep -v '^$'))
    PKG_COUNT=${#UNIQUE_PKGS[@]}
    
    if [[ ${PKG_COUNT} -gt 1 ]]; then
        ((TOTAL_MULTIPKG_DIRS++)) || true
        REL_DIR="${dir#${PROJECT_ROOT}/}"
        
        echo -e "  ${RED}⚠ ${REL_DIR}: ${PKG_COUNT} packages (${UNIQUE_PKGS[*]})${NC}"
        echo "  [STEP 4] Multi-package: ${REL_DIR} (${UNIQUE_PKGS[*]})" >> "${VERBOSE_LOG}"
        
        MULTIPKG_DETAILS+="──────────────────────────────────────────────\n"
        MULTIPKG_DETAILS+="DIRECTORY: ${REL_DIR}\n"
        MULTIPKG_DETAILS+="PACKAGES FOUND: ${PKG_COUNT}\n"
        MULTIPKG_DETAILS+="  Packages: ${UNIQUE_PKGS[*]}\n"
        
        DOMINANT_PKG=""
        DOMINANT_COUNT=0
        for pkg in "${UNIQUE_PKGS[@]}"; do
            FILES_FOR_PKG="$(echo "${DIR_FILES[${dir}]}" | tr ' ' '\n' | grep "|${pkg}$" | cut -d'|' -f1)"
            FILE_COUNT_FOR_PKG=$(echo "$FILES_FOR_PKG" | grep -c . 2>/dev/null || echo 0)
            [[ ${FILE_COUNT_FOR_PKG} -gt ${DOMINANT_COUNT} ]] && DOMINANT_COUNT=${FILE_COUNT_FOR_PKG} && DOMINANT_PKG="${pkg}"
            MULTIPKG_DETAILS+="  [${pkg}] ${FILE_COUNT_FOR_PKG} file(s)\n"
        done
        
        MINORITY_PKGS=(${UNIQUE_PKGS[@]/${DOMINANT_PKG}/})
        for minority_pkg in "${MINORITY_PKGS[@]}"; do
            [[ -z "${minority_pkg}" ]] && continue
            MINORITY_FILES="$(echo "${DIR_FILES[${dir}]}" | tr ' ' '\n' | grep "|${minority_pkg}$" | cut -d'|' -f1)"
            MINORITY_COUNT=$(echo "$MINORITY_FILES" | grep -c . 2>/dev/null || echo 0)
            MULTIPKG_DETAILS+="\n  Move ${MINORITY_COUNT} file(s) with '${minority_pkg}' to subdirectory:\n"
            SUGGESTED_SUBDIR="${dir}/${minority_pkg}"
            MULTIPKG_DETAILS+="    mkdir -p ${SUGGESTED_SUBDIR#${PROJECT_ROOT}/}\n"
            for f in $MINORITY_FILES; do
                MULTIPKG_DETAILS+="    mv ${f#${PROJECT_ROOT}/} ${SUGGESTED_SUBDIR#${PROJECT_ROOT}/}/\n"
            done
        done
        MULTIPKG_DETAILS+="──────────────────────────────────────────────\n\n"
        
        echo -e "    ${YELLOW}Dominant: ${DOMINANT_PKG} (${DOMINANT_COUNT} files)${NC}"
    fi
done

{
    echo "========================================================"
    echo "MULTIPLE PACKAGES IN SAME DIRECTORY"
    echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "========================================================"
    echo ""
    if [[ ${TOTAL_MULTIPKG_DIRS} -gt 0 ]]; then
        echo "Found ${TOTAL_MULTIPKG_DIRS} director(y/ies) with multiple packages:"
        echo ""
        echo -e "${MULTIPKG_DETAILS}"
    else
        echo "No multi-package directories found"
    fi
} > "${MULTIPKG_LOG}"

echo "[STEP 4] Complete. Found ${TOTAL_MULTIPKG_DIRS} multi-package dir(s)." >> "${VERBOSE_LOG}"
echo ""

# ── STEP 5: Dependency analysis ──
echo -e "${CYAN}[Step 5] Analyzing dependencies for potential removal...${NC}"
echo "[STEP 5] Analyzing dependencies..." >> "${VERBOSE_LOG}"

{
    echo "========================================================"
    echo "DEPENDENCY ANALYSIS"
    echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "========================================================"
    echo ""
} > "${DEPS_LOG}"

while IFS= read -r modfile; do
    MOD_DIR="$(dirname "${modfile}")"
    REL_DIR="${MOD_DIR#${PROJECT_ROOT}/}"
    [[ "${REL_DIR}" == "." ]] && REL_DIR="(root)"
    
    echo -e "${YELLOW}[${REL_DIR}] Analyzing go.mod...${NC}"
    echo "  [STEP 5] Module: ${REL_DIR}" >> "${VERBOSE_LOG}"
    echo "--- Module: ${REL_DIR} ---" >> "${DEPS_LOG}"
    
    MODULE_NAME="$(grep "^module " "${modfile}" | awk '{print $2}')"
    echo "Module name: ${MODULE_NAME}" >> "${DEPS_LOG}"
    echo "  Module name: ${MODULE_NAME}"
    
    ACTUAL_IMPORTS=""
    while IFS= read -r gofile; do
        IMPORTS=$(grep -h "\"[^\"]*\"" "${gofile}" 2>/dev/null | sed -E 's/.*"([^"]+)".*/\1/' | grep -v "^[[:space:]]*$" | sort -u)
        ACTUAL_IMPORTS="${ACTUAL_IMPORTS} ${IMPORTS}"
    done < <(find "${MOD_DIR}" -name "*.go" -type f -not -path "*/vendor/*" -not -path "*/.git/*" | sort)
    
    ACTUAL_IMPORTS=($(echo "${ACTUAL_IMPORTS}" | tr ' ' '\n' | sort -u | grep -v '^$'))
    
    DEPS=$(awk '/^require \(/{p=1; next} /^\)$/{p=0} p && /^[[:space:]]+[a-z]/{gsub(/^[[:space:]]+/,""); print}' "${modfile}")
    [[ -z "${DEPS}" ]] && DEPS=$(grep -E "^[[:space:]]+[a-zA-Z].*\sv[0-9]" "${modfile}" | sed -E 's/^[[:space:]]+([a-zA-Z].*)\s+v.*/\1/')
    
    declare -A GO_MOD_DEPS
    while IFS= read -r dep; do
        [[ -z "${dep}" ]] && continue
        DEPS_NAME=$(echo "${dep}" | awk '{print $1}')
        [[ -n "${DEPS_NAME}" ]] && GO_MOD_DEPS["${DEPS_NAME}"]=1
    done <<< "${DEPS}"
    
    UNUSABLE_DEPS=0
    EXTERNAL_DEPS=0
    LOCAL_DEPS=0
    DEPS_ANALYSIS=""
    
    for dep in "${!GO_MOD_DEPS[@]}"; do
        is_stdlib "${dep}" && { ((LOCAL_DEPS++)) || true; continue; }
        
        DEP_BASENAME=$(basename "${dep}")
        IS_LOCAL_SIBLING=false
        for sibling in "${MODULE_PATHS_ARRAY[@]}"; do
            [[ "$(basename "${sibling}")" == "${DEP_BASENAME}" ]] && IS_LOCAL_SIBLING=true && break
        done
        
        [[ "${IS_LOCAL_SIBLING}" == "true" ]] && { ((TOTAL_LOCAL_DEPS++)) || true; ((LOCAL_DEPS++)) || true; continue; }
        
        ((TOTAL_EXTERNAL_DEPS++)) || true
        ((EXTERNAL_DEPS++)) || true
        
        FOUND_IMPORT=false
        for actual_import in "${ACTUAL_IMPORTS[@]}"; do
            [[ "${actual_import}" == "${dep}"* ]] && FOUND_IMPORT=true && break
        done
        
        if [[ "${FOUND_IMPORT}" == "false" ]]; then
            ((UNUSABLE_DEPS++)) || true
            ((TOTAL_UNUSED_DEPS++)) || true
            echo "    ${RED}⚠ ${dep} - NOT USED${NC}"
            DEPS_ANALYSIS+="  [NOT USED] ${dep}\n    Reason: Not found in any imports\n\n"
            echo "  [STEP 5] Unused: ${dep}" >> "${VERBOSE_LOG}"
        else
            echo "    ${GREEN}✓ ${dep} - USED${NC}"
        fi
    done
    
    unset GO_MOD_DEPS
    
    if [[ ${UNUSABLE_DEPS} -gt 0 ]]; then
        echo "Unused external dependencies (${UNUSABLE_DEPS}):" >> "${DEPS_LOG}"
        echo -e "${DEPS_ANALYSIS}" >> "${DEPS_LOG}"
        echo "Summary: ${EXTERNAL_DEPS} external, ${LOCAL_DEPS} stdlib/local, ${UNUSABLE_DEPS} unused" >> "${DEPS_LOG}"
    else
        echo "All external dependencies are actively used" >> "${DEPS_LOG}"
        echo "Summary: ${EXTERNAL_DEPS} external, ${LOCAL_DEPS} stdlib/local, 0 unused" >> "${DEPS_LOG}"
    fi
    echo "" >> "${DEPS_LOG}"
    echo -e "    ${CYAN}Ext: ${EXTERNAL_DEPS}, Local: ${LOCAL_DEPS}, Unused: ${UNUSABLE_DEPS}${NC}"
    echo ""
    echo "[STEP 5] ${REL_DIR}: ${EXTERNAL_DEPS} ext, ${LOCAL_DEPS} local, ${UNUSABLE_DEPS} unused" >> "${VERBOSE_LOG}"
done < <(find "${PROJECT_ROOT}" -name "go.mod" -type f -not -path "*/.git/*" -not -path "*/vendor/*" | sort)

{
    echo "========================================================"
    echo "DEPENDENCY SUMMARY"
    echo "Total unused external: ${TOTAL_UNUSED_DEPS}"
    echo "Total external: ${TOTAL_EXTERNAL_DEPS}"
    echo "Total stdlib/local: ${TOTAL_LOCAL_DEPS}"
    [[ ${TOTAL_UNUSED_DEPS} -gt 0 ]] && echo "" && echo "Run 'go mod tidy' in affected modules"
    echo "========================================================"
} >> "${DEPS_LOG}"

echo "[STEP 5] Complete. ${TOTAL_UNUSED_DEPS} unused dep(s)." >> "${VERBOSE_LOG}"
echo ""

# ── STEP 6: Run checks on existing modules ──
echo -e "${CYAN}[Step 6] Running checks on existing modules...${NC}"
echo "[STEP 6] Running checks on existing modules..." >> "${VERBOSE_LOG}"

# Issues aggregation buffer
ISSUES_BUFFER=""

while IFS= read -r modfile; do
    MOD_DIR="$(dirname "${modfile}")"
    REL_DIR="${MOD_DIR#${PROJECT_ROOT}/}"
    TOTAL_MODULES=$((TOTAL_MODULES + 1))

    GO_FILE_COUNT=$(find "${MOD_DIR}" -name "*.go" -not -path "*/vendor/*" -not -path "*/.git/*" | wc -l)

    echo -e "${YELLOW}[${TOTAL_MODULES}] Module: ${REL_DIR} (${GO_FILE_COUNT} Go files)${NC}"
    echo "" >> "${VERBOSE_LOG}"
    echo "──────────────────────────────────────────────────────────" >> "${VERBOSE_LOG}"
    echo "MODULE: ${REL_DIR}" >> "${VERBOSE_LOG}"
    echo "PATH: ${MOD_DIR}" >> "${VERBOSE_LOG}"
    echo "FILES: ${GO_FILE_COUNT}" >> "${VERBOSE_LOG}"
    echo "──────────────────────────────────────────────────────────" >> "${VERBOSE_LOG}"
    {
        echo "[FILES] Go files in module:"
        find "${MOD_DIR}" -name "*.go" -not -path "*/vendor/*" -not -path "*/.git/*" | sort | sed 's/^/  /'
        echo ""
    } >> "${VERBOSE_LOG}"

    MODULE_LOG="${RESULTS_DIR}/$(echo "${REL_DIR}" | tr '/' '_').log"
    {
        echo "=== Module: ${REL_DIR} ==="
        echo "Path: ${MOD_DIR}"
        echo "Files: ${GO_FILE_COUNT}"
        echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
        echo ""
    } > "${MODULE_LOG}"

    PROBLEM_COUNT=0

    # ── go vet ──
    echo "  → go vet ./..."
    echo "[GO VET] command: go vet ./..." >> "${VERBOSE_LOG}"
    VET_OUTPUT=""
    VET_EXIT=0
    VET_OUTPUT="$(cd "${MOD_DIR}" && go vet ./... 2>&1)" || VET_EXIT=$?
    
    if [[ ${VET_EXIT} -eq 0 ]]; then
        echo "[GO VET] status: PASS (clean)" >> "${VERBOSE_LOG}"
        echo "[GO VET] issues found: 0" >> "${VERBOSE_LOG}"
        echo "[GO VET] raw output: (no output — no issues detected)" >> "${VERBOSE_LOG}"
        echo "✓ go vet passed" >> "${MODULE_LOG}"
        echo "  ${GREEN}✓ go vet: clean${NC}"
    else
        VET_COUNT=$(echo "${VET_OUTPUT}" | grep -c . 2>/dev/null || echo 0)
        echo "[GO VET] status: FAIL (${VET_COUNT} issues)" >> "${VERBOSE_LOG}"
        echo "[GO VET] raw output:" >> "${VERBOSE_LOG}"
        echo "${VET_OUTPUT}" | sed 's/^/  /' >> "${VERBOSE_LOG}"
        echo "${VET_OUTPUT}" >> "${MODULE_LOG}"
        echo "✗ go vet found ${VET_COUNT} issue(s)" >> "${MODULE_LOG}"
        PROBLEM_COUNT=$((PROBLEM_COUNT + VET_COUNT))
        TOTAL_VET_ISSUES=$((TOTAL_VET_ISSUES + VET_COUNT))
        
        echo -e "  ${RED}✗ go vet: ${VET_COUNT} issue(s)${NC}"
        echo "${VET_OUTPUT}" | while IFS= read -r line; do
            echo -e "    ${RED}vet: ${line}${NC}"
        done
        
        # Aggregate into issues buffer
        ISSUES_BUFFER+="──────────────────────────────────────────────\n"
        ISSUES_BUFFER+="MODULE: ${REL_DIR}\n"
        ISSUES_BUFFER+="TOOL: go vet (${VET_COUNT} issues)\n"
        ISSUES_BUFFER+="\n"
        while IFS= read -r line; do
            ISSUES_BUFFER+="  ${line}\n"
        done <<< "${VET_OUTPUT}"
        ISSUES_BUFFER+="\n"
    fi
    echo "" >> "${VERBOSE_LOG}"
    echo "--- go vet ---" >> "${MODULE_LOG}"

    # ── gofmt -l ──
    echo "  → gofmt -l"
    echo "[GOFMT] command: gofmt -l ." >> "${VERBOSE_LOG}"
    FMT_OUTPUT="$(cd "${MOD_DIR}" && gofmt -l . 2>&1)" || true
    
    if [[ -n "${FMT_OUTPUT}" ]]; then
        FMT_COUNT=$(echo "${FMT_OUTPUT}" | wc -l)
        echo "[GOFMT] status: ISSUES FOUND (${FMT_COUNT} unformatted files)" >> "${VERBOSE_LOG}"
        echo "[GOFMT] raw output:" >> "${VERBOSE_LOG}"
        echo "${FMT_OUTPUT}" | sed 's/^/  /' >> "${VERBOSE_LOG}"
        echo "${FMT_OUTPUT}" >> "${MODULE_LOG}"
        PROBLEM_COUNT=$((PROBLEM_COUNT + FMT_COUNT))
        TOTAL_FMT_ISSUES=$((TOTAL_FMT_ISSUES + FMT_COUNT))
        
        echo -e "  ${RED}✗ gofmt: ${FMT_COUNT} unformatted file(s)${NC}"
        echo "${FMT_OUTPUT}" | while IFS= read -r line; do
            echo -e "    ${RED}fmt: ${line}${NC}"
        done
        
        ISSUES_BUFFER+="──────────────────────────────────────────────\n"
        ISSUES_BUFFER+="MODULE: ${REL_DIR}\n"
        ISSUES_BUFFER+="TOOL: gofmt (${FMT_COUNT} unformatted files)\n"
        ISSUES_BUFFER+="\n"
        while IFS= read -r line; do
            ISSUES_BUFFER+="  ${line}\n"
        done <<< "${FMT_OUTPUT}"
        ISSUES_BUFFER+="\n"
    else
        echo "[GOFMT] status: PASS (all formatted)" >> "${VERBOSE_LOG}"
        echo "[GOFMT] raw output: (no output — all formatted)" >> "${VERBOSE_LOG}"
        echo "No formatting issues" >> "${MODULE_LOG}"
        echo "  ${GREEN}✓ gofmt: all formatted${NC}"
    fi
    echo "" >> "${VERBOSE_LOG}"

    # ── staticcheck ──
    echo "  → staticcheck ./..."
    echo "[STATICCHECK] command: staticcheck ./..." >> "${VERBOSE_LOG}"
    
    if command -v staticcheck &>/dev/null; then
        STATIC_OUTPUT="$(cd "${MOD_DIR}" && staticcheck ./... 2>&1)" || true
        
        if [[ -n "${STATIC_OUTPUT}" ]]; then
            SC_COUNT=$(echo "${STATIC_OUTPUT}" | grep -c . 2>/dev/null || echo 0)
            echo "[STATICCHECK] status: ISSUES FOUND (${SC_COUNT})" >> "${VERBOSE_LOG}"
            echo "[STATICCHECK] raw output:" >> "${VERBOSE_LOG}"
            echo "${STATIC_OUTPUT}" | sed 's/^/  /' >> "${VERBOSE_LOG}"
            echo "${STATIC_OUTPUT}" >> "${MODULE_LOG}"
            PROBLEM_COUNT=$((PROBLEM_COUNT + SC_COUNT))
            TOTAL_STATIC_ISSUES=$((TOTAL_STATIC_ISSUES + SC_COUNT))
            
            echo -e "  ${RED}✗ staticcheck: ${SC_COUNT} issue(s)${NC}"
            echo "${STATIC_OUTPUT}" | while IFS= read -r line; do
                echo -e "    ${RED}sc: ${line}${NC}"
            done
            
            ISSUES_BUFFER+="──────────────────────────────────────────────\n"
            ISSUES_BUFFER+="MODULE: ${REL_DIR}\n"
            ISSUES_BUFFER+="TOOL: staticcheck (${SC_COUNT} issues)\n"
            ISSUES_BUFFER+="\n"
            while IFS= read -r line; do
                ISSUES_BUFFER+="  ${line}\n"
            done <<< "${STATIC_OUTPUT}"
            ISSUES_BUFFER+="\n"
        else
            echo "[STATICCHECK] status: PASS (clean)" >> "${VERBOSE_LOG}"
            echo "[STATICCHECK] raw output: (no output — no issues)" >> "${VERBOSE_LOG}"
            echo "No issues found" >> "${MODULE_LOG}"
            echo "  ${GREEN}✓ staticcheck: clean${NC}"
        fi
    else
        echo "[STATICCHECK] status: SKIPPED (not installed)" >> "${VERBOSE_LOG}"
        echo "Install: go install honnef.co/go/tools/cmd/staticcheck@latest" >> "${MODULE_LOG}"
        echo "  ${YELLOW}⊘ staticcheck: not installed${NC}"
    fi
    echo "" >> "${VERBOSE_LOG}"

    # ── go build ──
    echo -e "  ${BLUE}→ checking dependencies (go build)...${NC}"
    echo "[GO BUILD] command: go build ./..." >> "${VERBOSE_LOG}"
    BUILD_OUTPUT="$(cd "${MOD_DIR}" && go build ./... 2>&1)" || true
    
    MISSING_DEPS="$(echo "${BUILD_OUTPUT}" | grep -E "cannot find package|no required module provides package|is not in stdlib|package .* is not in std" | sort -u || true)"
    OTHER_ERRORS="$(echo "${BUILD_OUTPUT}" | grep -v "cannot find package\|no required module provides package\|is not in stdlib\|package .* is not in std" | grep -E "\.go:[0-9]+" | sort -u || true)"
    
    if [[ -n "${MISSING_DEPS}" ]]; then
        DEP_COUNT=$(echo "${MISSING_DEPS}" | wc -l)
        echo "[GO BUILD] status: MISSING PACKAGES (${DEP_COUNT})" >> "${VERBOSE_LOG}"
        echo "[GO BUILD] missing packages:" >> "${VERBOSE_LOG}"
        echo "${MISSING_DEPS}" | sed 's/^/  /' >> "${VERBOSE_LOG}"
        echo "${MISSING_DEPS}" >> "${MODULE_LOG}"
        PROBLEM_COUNT=$((PROBLEM_COUNT + DEP_COUNT))
        TOTAL_MISSING_DEPS=$((TOTAL_MISSING_DEPS + DEP_COUNT))
        TOTAL_BUILD_ISSUES=$((TOTAL_BUILD_ISSUES + DEP_COUNT))
        
        echo -e "  ${RED}⚠ ${DEP_COUNT} missing dependencies${NC}"
        echo "${MISSING_DEPS}" | while IFS= read -r line; do
            echo -e "    ${RED}dep: ${line}${NC}"
        done
        
        echo "" >> "${MODULE_LOG}"
        echo "Suggested fixes:" >> "${MODULE_LOG}"
        echo "${MISSING_DEPS}" | grep -oE '"[^"]+"' | sort -u | while read -r pkg; do
            CLEAN_PKG="${pkg//\"/}"
            echo "  cd ${MOD_DIR} && go get ${CLEAN_PKG}" >> "${MODULE_LOG}"
        done
        
        ISSUES_BUFFER+="──────────────────────────────────────────────\n"
        ISSUES_BUFFER+="MODULE: ${REL_DIR}\n"
        ISSUES_BUFFER+="TOOL: go build — MISSING DEPENDENCIES (${DEP_COUNT})\n"
        ISSUES_BUFFER+="\n"
        while IFS= read -r line; do
            ISSUES_BUFFER+="  ${line}\n"
        done <<< "${MISSING_DEPS}"
        ISSUES_BUFFER+="\n"
    elif [[ -n "${OTHER_ERRORS}" ]]; then
        ERR_COUNT=$(echo "${OTHER_ERRORS}" | wc -l)
        echo "[GO BUILD] status: BUILD ERROR (${ERR_COUNT})" >> "${VERBOSE_LOG}"
        echo "[GO BUILD] errors:" >> "${VERBOSE_LOG}"
        echo "${OTHER_ERRORS}" | sed 's/^/  /' >> "${VERBOSE_LOG}"
        echo "${OTHER_ERRORS}" >> "${MODULE_LOG}"
        PROBLEM_COUNT=$((PROBLEM_COUNT + ERR_COUNT))
        TOTAL_BUILD_ISSUES=$((TOTAL_BUILD_ISSUES + ERR_COUNT))
        
        echo -e "  ${RED}✗ go build: ${ERR_COUNT} error(s)${NC}"
        echo "${OTHER_ERRORS}" | while IFS= read -r line; do
            echo -e "    ${RED}build: ${line}${NC}"
        done
        
        ISSUES_BUFFER+="──────────────────────────────────────────────\n"
        ISSUES_BUFFER+="MODULE: ${REL_DIR}\n"
        ISSUES_BUFFER+="TOOL: go build — BUILD ERRORS (${ERR_COUNT})\n"
        ISSUES_BUFFER+="\n"
        while IFS= read -r line; do
            ISSUES_BUFFER+="  ${line}\n"
        done <<< "${OTHER_ERRORS}"
        ISSUES_BUFFER+="\n"
    else
        echo "[GO BUILD] status: PASS (build successful)" >> "${VERBOSE_LOG}"
        echo "[GO BUILD] raw output: (no output — build successful)" >> "${VERBOSE_LOG}"
        echo "All dependencies present, build successful" >> "${MODULE_LOG}"
        echo "  ${GREEN}✓ go build: success${NC}"
    fi
    echo "" >> "${VERBOSE_LOG}"

    # ── go mod tidy -diff ──
    echo "[GO MOD TIDY] command: go mod tidy -diff" >> "${VERBOSE_LOG}"
    TIDY_OUTPUT="$(cd "${MOD_DIR}" && go mod tidy -diff 2>&1)" || true
    
    if [[ -n "${TIDY_OUTPUT}" ]]; then
        echo "[GO MOD TIDY] status: CHANGES NEEDED" >> "${VERBOSE_LOG}"
        echo "[GO MOD TIDY] diff:" >> "${VERBOSE_LOG}"
        echo "${TIDY_OUTPUT}" | sed 's/^/  /' >> "${VERBOSE_LOG}"
        echo "${TIDY_OUTPUT}" >> "${MODULE_LOG}"
        ((PROBLEM_COUNT++)) || true
        TOTAL_TIDY_ISSUES=$((TOTAL_TIDY_ISSUES + 1))
        echo -e "  ${YELLOW}⚠ go mod tidy: changes needed${NC}"
        
        ISSUES_BUFFER+="──────────────────────────────────────────────\n"
        ISSUES_BUFFER+="MODULE: ${REL_DIR}\n"
        ISSUES_BUFFER+="TOOL: go mod tidy — CHANGES NEEDED\n"
        ISSUES_BUFFER+="\n"
        while IFS= read -r line; do
            ISSUES_BUFFER+="  ${line}\n"
        done <<< "${TIDY_OUTPUT}"
        ISSUES_BUFFER+="\n"
    else
        echo "[GO MOD TIDY] status: PASS (consistent)" >> "${VERBOSE_LOG}"
        echo "No changes needed" >> "${MODULE_LOG}"
        echo "  ${GREEN}✓ go mod tidy: consistent${NC}"
    fi
    echo "" >> "${VERBOSE_LOG}"

    # Module result
    echo "" >> "${MODULE_LOG}"
    echo "Total problems this module: ${PROBLEM_COUNT}" >> "${MODULE_LOG}"
    [[ ${PROBLEM_COUNT} -gt 0 ]] && echo "MODULE STATUS: ISSUES FOUND" >> "${MODULE_LOG}" || echo "MODULE STATUS: CLEAN" >> "${MODULE_LOG}"
    
    echo "[RESULT] ${REL_DIR}: ${PROBLEM_COUNT} problems" >> "${VERBOSE_LOG}"
    
    if [[ ${PROBLEM_COUNT} -gt 0 ]]; then
        echo -e "  ${RED}✗ ${PROBLEM_COUNT} problems${NC} → ${MODULE_LOG}"
    else
        echo -e "  ${GREEN}✓ Clean${NC}"
    fi
    TOTAL_PROBLEMS=$((TOTAL_PROBLEMS + PROBLEM_COUNT))
    echo ""
done < <(find "${PROJECT_ROOT}" -name "go.mod" -type f -not -path "*/.git/*" -not -path "*/vendor/*" | sort)

echo "[STEP 6] Complete. Checked ${TOTAL_MODULES} module(s)." >> "${VERBOSE_LOG}"
echo ""

# ── STEP 7: Syntax check orphaned files ──
echo -e "${CYAN}[Step 7] Syntax checking orphaned files...${NC}"
echo "[STEP 7] Syntax checking orphaned files..." >> "${VERBOSE_LOG}"

if [[ ${TOTAL_ORPHAN_FILES} -gt 0 ]]; then
    ORPHAN_ERROR_COUNT=0
    for orphan in "${ORPHAN_GO_FILES[@]}"; do
        if ! go tool compile -p "main" -e "${orphan}" 2>>"${ORPHANS_LOG}" >/dev/null; then
            ((ORPHAN_ERROR_COUNT++)) || true
        fi
    done
    
    if [[ ${ORPHAN_ERROR_COUNT} -gt 0 ]]; then
        echo "  ${RED}${ORPHAN_ERROR_COUNT} orphaned files have syntax errors${NC}"
        echo "[STEP 7] ${ORPHAN_ERROR_COUNT} syntax errors." >> "${VERBOSE_LOG}"
    else
        echo "  ${GREEN}All orphaned files pass syntax check${NC}"
        echo "[STEP 7] All pass." >> "${VERBOSE_LOG}"
    fi
else
    echo "[STEP 7] No orphaned files." >> "${VERBOSE_LOG}"
fi
echo ""

# ── Write aggregated issues log ──
{
    echo "========================================================"
    echo "AGGREGATED ISSUES FROM ALL TOOLS"
    echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "Project root: ${PROJECT_ROOT}"
    echo "========================================================"
    echo ""
    echo "ISSUE COUNT BY TOOL:"
    echo "  go vet:        ${TOTAL_VET_ISSUES} issue(s)"
    echo "  gofmt:         ${TOTAL_FMT_ISSUES} unformatted file(s)"
    echo "  staticcheck:   ${TOTAL_STATIC_ISSUES} issue(s)"
    echo "  go build:      ${TOTAL_BUILD_ISSUES} error(s) / missing dep(s)"
    echo "  go mod tidy:   ${TOTAL_TIDY_ISSUES} module(s) needing cleanup"
    echo "  ─────────────────────────────────"
    echo "  TOTAL:         ${TOTAL_PROBLEMS} problem(s)"
    echo ""
    echo "========================================================"
    
    if [[ -n "${ISSUES_BUFFER}" ]]; then
        echo ""
        echo "DETAILED ISSUES BY MODULE AND TOOL:"
        echo ""
        echo -e "${ISSUES_BUFFER}"
    else
        echo ""
        echo "NO ISSUES FOUND — ALL CHECKS PASSED"
        echo ""
    fi
    
    echo "========================================================"
    echo "ISSUE LOG COMPLETE"
    echo "========================================================"
} > "${ISSUES_LOG}"

# ── Summary ──
SUMMARY="${RESULTS_DIR}/summary.log"
{
    echo "=== GO CHECK SUMMARY ==="
    echo "Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "Project root: ${PROJECT_ROOT}"
    echo ""
    echo "MODULES"
    echo "  Modules checked: ${TOTAL_MODULES}"
    echo "  Go files in modules: ${TOTAL_FILES}"
    echo "  Total problems: ${TOTAL_PROBLEMS}"
    echo ""
    echo "ISSUES BY TOOL"
    echo "  go vet:       ${TOTAL_VET_ISSUES}"
    echo "  gofmt:        ${TOTAL_FMT_ISSUES}"
    echo "  staticcheck:  ${TOTAL_STATIC_ISSUES}"
    echo "  go build:     ${TOTAL_BUILD_ISSUES}"
    echo "  go mod tidy:  ${TOTAL_TIDY_ISSUES}"
    echo ""
    echo "ORPHANS"
    echo "  Orphaned Go files: ${TOTAL_ORPHAN_FILES}"
    echo ""
    echo "MULTI-PACKAGE"
    echo "  Directories: ${TOTAL_MULTIPKG_DIRS}"
    echo ""
    echo "DEPENDENCIES"
    echo "  External: ${TOTAL_EXTERNAL_DEPS}"
    echo "  Stdlib/Local: ${TOTAL_LOCAL_DEPS}"
    echo "  Unused external: ${TOTAL_UNUSED_DEPS}"
    echo "  Missing: ${TOTAL_MISSING_DEPS}"
    echo ""
    echo "SUGGESTIONS"
    echo "  Potential new modules: ${TOTAL_SUGGESTED_MODULES}"
    echo ""
    echo "PER-MODULE BREAKDOWN"
    for f in "${RESULTS_DIR}"/*.log; do
        [[ "$(basename "$f")" == "summary.log" ]] && continue
        [[ "$(basename "$f")" == "verbose.log" ]] && continue
        [[ "$(basename "$f")" == "orphans.log" ]] && continue
        [[ "$(basename "$f")" == "module-suggestions.log" ]] && continue
        [[ "$(basename "$f")" == "multi-package.log" ]] && continue
        [[ "$(basename "$f")" == "dependency-analysis.log" ]] && continue
        [[ "$(basename "$f")" == "issues.log" ]] && continue
        COUNT=$(grep "^Total problems" "$f" 2>/dev/null | awk '{print $NF}' || echo "?")
        echo "  $(basename "$f"): ${COUNT} problems"
    done
} > "${SUMMARY}"

# ── Verbose footer ──
{
    echo "========================================================"
    echo "VERBOSE LOG COMPLETE"
    echo "Modules: ${TOTAL_MODULES}"
    echo "Files in modules: ${TOTAL_FILES}"
    echo "Orphaned files: ${TOTAL_ORPHAN_FILES}"
    echo "Multi-package dirs: ${TOTAL_MULTIPKG_DIRS}"
    echo "Issues — vet: ${TOTAL_VET_ISSUES}, fmt: ${TOTAL_FMT_ISSUES}, sc: ${TOTAL_STATIC_ISSUES}, build: ${TOTAL_BUILD_ISSUES}, tidy: ${TOTAL_TIDY_ISSUES}"
    echo "External deps: ${TOTAL_EXTERNAL_DEPS}, Unused: ${TOTAL_UNUSED_DEPS}"
    echo "Total problems: ${TOTAL_PROBLEMS}"
    echo "Missing dependencies: ${TOTAL_MISSING_DEPS}"
    echo "Suggested new modules: ${TOTAL_SUGGESTED_MODULES}"
    echo "========================================================"
} >> "${VERBOSE_LOG}"

# ── Final console output ──
echo "========================================"
echo -e "  ${CYAN}Modules checked:${NC} ${TOTAL_MODULES}"
echo -e "  ${CYAN}Go files in modules:${NC} ${TOTAL_FILES}"
echo -e "  ${CYAN}Orphaned files:${NC} ${TOTAL_ORPHAN_FILES}"
echo -e "  ${RED}Multi-package dirs:${NC} ${TOTAL_MULTIPKG_DIRS}"
echo -e "  ${RED}Total problems:${NC} ${TOTAL_PROBLEMS}"
echo ""
echo -e "  ${RED}Issues by tool:${NC}"
echo -e "    go vet:       ${TOTAL_VET_ISSUES}"
echo -e "    gofmt:        ${TOTAL_FMT_ISSUES}"
echo -e "    staticcheck:  ${TOTAL_STATIC_ISSUES}"
echo -e "    go build:     ${TOTAL_BUILD_ISSUES}"
echo -e "    go mod tidy:  ${TOTAL_TIDY_ISSUES}"
echo ""
echo -e "  ${BLUE}External deps:${NC} ${TOTAL_EXTERNAL_DEPS}"
echo -e "  ${BLUE}Stdlib/Local deps:${NC} ${TOTAL_LOCAL_DEPS}"
echo -e "  ${RED}Unused external deps:${NC} ${TOTAL_UNUSED_DEPS}"
echo -e "  ${RED}Missing deps:${NC} ${TOTAL_MISSING_DEPS}"
echo -e "  ${MAGENTA}Suggested modules:${NC} ${TOTAL_SUGGESTED_MODULES}"
echo ""
echo -e "  ${CYAN}Issues log:${NC} ${ISSUES_LOG}"
echo -e "  ${CYAN}Verbose log:${NC} ${VERBOSE_LOG}"
echo -e "  ${CYAN}Orphans:${NC} ${ORPHANS_LOG}"
echo -e "  ${CYAN}Multi-package:${NC} ${MULTIPKG_LOG}"
echo -e "  ${CYAN}Dependencies:${NC} ${DEPS_LOG}"
echo -e "  ${CYAN}Suggestions:${NC} ${SUGGESTIONS_LOG}"
echo -e "  ${CYAN}Summary:${NC} ${SUMMARY}"
echo "========================================"

if [[ ${TOTAL_PROBLEMS} -gt 0 ]]; then
    echo -e "\n${RED}Issues found (${TOTAL_PROBLEMS}). Detailed breakdown:${NC}"
    echo ""
    echo -e "${CYAN}cat ${ISSUES_LOG}${NC}"
    echo ""
    # Print actual issues to console
    if [[ ${TOTAL_VET_ISSUES} -gt 0 ]]; then
        echo -e "${RED}── go vet issues (${TOTAL_VET_ISSUES}) ──${NC}"
        grep -A999 "TOOL: go vet" "${ISSUES_LOG}" | grep -B999 "TOOL: gofmt" | head -n -2
        echo ""
    fi
    if [[ ${TOTAL_FMT_ISSUES} -gt 0 ]]; then
        echo -e "${RED}── gofmt issues (${TOTAL_FMT_ISSUES}) ──${NC}"
        grep -A999 "TOOL: gofmt" "${ISSUES_LOG}" | grep -B999 "TOOL: staticcheck" | head -n -2
        echo ""
    fi
    if [[ ${TOTAL_STATIC_ISSUES} -gt 0 ]]; then
        echo -e "${RED}── staticcheck issues (${TOTAL_STATIC_ISSUES}) ──${NC}"
        grep -A999 "TOOL: staticcheck" "${ISSUES_LOG}" | grep -B999 "TOOL: go build" | head -n -2
        echo ""
    fi
    if [[ ${TOTAL_BUILD_ISSUES} -gt 0 ]]; then
        echo -e "${RED}── go build issues (${TOTAL_BUILD_ISSUES}) ──${NC}"
        grep -A999 "TOOL: go build" "${ISSUES_LOG}" | grep -B999 "TOOL: go mod tidy" | head -n -2
        echo ""
    fi
fi

if [[ ${TOTAL_UNUSED_DEPS} -gt 0 ]]; then
    echo -e "${RED}Unused dependencies (${TOTAL_UNUSED_DEPS}). See:${NC}"
    echo "  cat ${DEPS_LOG}"
    echo ""
fi

if [[ ${TOTAL_MULTIPKG_DIRS} -gt 0 ]]; then
    echo -e "${RED}Multi-package dirs (${TOTAL_MULTIPKG_DIRS}). See:${NC}"
    echo "  cat ${MULTIPKG_LOG}"
    echo ""
fi

if [[ ${TOTAL_ORPHAN_FILES} -gt 0 ]]; then
    echo -e "${MAGENTA}Orphaned files (${TOTAL_ORPHAN_FILES}). See:${NC}"
    echo "  cat ${ORPHANS_LOG}"
    echo "  cat ${SUGGESTIONS_LOG}"
    echo ""
fi

if [[ ${TOTAL_MISSING_DEPS} -gt 0 ]]; then
    echo -e "${RED}Missing dependencies. Run:${NC}"
    grep "go get" "${RESULTS_DIR}"/*.log 2>/dev/null | grep -v "Install:" | sort -u
    echo ""
fi