#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认值
DEFAULT_CFIP="cf.877774.xyz"
DEFAULT_CFPORT="443"
DEFAULT_ARGO_PORT="8001"

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示使用说明
show_usage() {
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  --email EMAIL         SAP账号邮箱 (必需)"
    echo "  --password PASSWORD   SAP账号密码 (必需)"
    echo "  --region REGION       部署区域 (sg 或 us, 默认: sg)"
    echo "  --uuid UUID           UUID (必需)"
    echo "  --argo-domain DOMAIN  Argo隧道域名 (必需)"
    echo "  --argo-auth AUTH      Argo隧道密钥 (必需)"
    echo "  --sub-path PATH       订阅路径 (必需)"
    echo "  --cfip IP             CF IP (默认: $DEFAULT_CFIP)"
    echo "  --cfport PORT         CF端口 (默认: $DEFAULT_CFPORT)"
    echo "  --argo-port PORT      Argo端口 (默认: $DEFAULT_ARGO_PORT)"
    echo "  -h                    显示此帮助信息"
    echo ""
    echo "环境变量:"
    echo "  SAP_EMAIL             SAP账号邮箱 (必需)"
    echo "  SAP_PASSWORD           SAP账号密码 (必需)"
    echo "  SAP_REGION             部署区域 (默认: sg)"
    echo "  SAP_UUID               UUID (必需)"
    echo "  SAP_ARGO_DOMAIN        Argo隧道域名 (必需)"
    echo "  SAP_ARGO_AUTH          Argo隧道密钥 (必需)"
    echo "  SAP_SUB_PATH           订阅路径 (必需)"
    echo "  SAP_CFIP               CF IP (默认: $DEFAULT_CFIP)"
    echo "  SAP_CFPORT             CF端口 (默认: $DEFAULT_CFPORT)"
    echo "  SAP_ARGO_PORT          Argo端口 (默认: $DEFAULT_ARGO_PORT)"
    echo ""
    echo "示例:"
    echo "  $0 --email user@example.com --password pass123 --region us --uuid your-uuid --argo-domain your-domain.com --argo-auth your-auth --sub-path your-path"
    echo "  SAP_EMAIL=user@example.com SAP_PASSWORD=pass123 $0 --region us"
    echo ""
    echo "配置文件:"
    echo "  您也可以创建一个 .env 文件来存储配置，脚本会自动加载"
    echo "  .env 文件示例:"
    echo "  SAP_EMAIL=user@example.com"
    echo "  SAP_PASSWORD=pass123"
    echo "  SAP_REGION=us"
    echo "  SAP_UUID=your-uuid"
    echo "  SAP_ARGO_DOMAIN=your-domain.com"
    echo "  SAP_ARGO_AUTH=your-auth"
    echo "  SAP_SUB_PATH=your-path"
}

# 检查命令是否存在
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 生成随机应用名
generate_app_name() {
    local prefix="argo"
    local random_str=$(head /dev/urandom | tr -dc 'a-z0-9' | head -c 6)
    echo "${prefix}-${random_str}"
}

# 加载环境变量文件
load_env_file() {
    if [ -f ".env" ]; then
        print_info "加载 .env 文件中的配置..."
        set -a
        source .env
        set +a
    fi
}

# 验证必需参数
validate_required_params() {
    local missing_params=()
    
    if [ -z "$EMAIL" ]; then
        missing_params+=("EMAIL")
    fi
    
    if [ -z "$PASSWORD" ]; then
        missing_params+=("PASSWORD")
    fi
    
    if [ -z "$UUID" ]; then
        missing_params+=("UUID")
    fi
    
    if [ -z "$ARGO_DOMAIN" ]; then
        missing_params+=("ARGO_DOMAIN")
    fi
    
    if [ -z "$ARGO_AUTH" ]; then
        missing_params+=("ARGO_AUTH")
    fi
    
    if [ -z "$SUB_PATH" ]; then
        missing_params+=("SUB_PATH")
    fi
    
    if [ ${#missing_params[@]} -gt 0 ]; then
        print_error "缺少必需的参数: ${missing_params[*]}"
        print_error "请通过命令行参数、环境变量或 .env 文件提供这些参数"
        show_usage
        exit 1
    fi
}

# 解析命令行参数
parse_arguments() {
    # 加载环境变量文件
    load_env_file
    
    # 设置默认值
    REGION="${SAP_REGION:-sg}"
    CFIP="${SAP_CFIP:-$DEFAULT_CFIP}"
    CFPORT="${SAP_CFPORT:-$DEFAULT_CFPORT}"
    ARGO_PORT="${SAP_ARGO_PORT:-$DEFAULT_ARGO_PORT}"
    
    # 从环境变量获取值
    EMAIL="${SAP_EMAIL:-}"
    PASSWORD="${SAP_PASSWORD:-}"
    UUID="${SAP_UUID:-}"
    ARGO_DOMAIN="${SAP_ARGO_DOMAIN:-}"
    ARGO_AUTH="${SAP_ARGO_AUTH:-}"
    SUB_PATH="${SAP_SUB_PATH:-}"
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            --email)
                EMAIL="$2"
                shift 2
                ;;
            --password)
                PASSWORD="$2"
                shift 2
                ;;
            --region)
                REGION="$2"
                shift 2
                ;;
            --uuid)
                UUID="$2"
                shift 2
                ;;
            --argo-domain)
                ARGO_DOMAIN="$2"
                shift 2
                ;;
            --argo-auth)
                ARGO_AUTH="$2"
                shift 2
                ;;
            --sub-path)
                SUB_PATH="$2"
                shift 2
                ;;
            --cfip)
                CFIP="$2"
                shift 2
                ;;
            --cfport)
                CFPORT="$2"
                shift 2
                ;;
            --argo-port)
                ARGO_PORT="$2"
                shift 2
                ;;
            -h)
                show_usage
                exit 0
                ;;
            *)
                print_error "无效的参数: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # 验证必需参数
    validate_required_params
    
    # 设置API端点
    case $REGION in
        sg)
            API_ENDPOINT="https://api.cf.ap21.hana.ondemand.com"
            ;;
        us)
            API_ENDPOINT="https://api.cf.us10-001.hana.ondemand.com"
            ;;
        *)
            print_error "无效的区域: $REGION，请使用 'sg' 或 'us'"
            exit 1
            ;;
    esac
    
    print_info "配置信息:"
    print_info "  邮箱: ${EMAIL:0:3}***@${EMAIL#*@}"
    print_info "  区域: $REGION"
    print_info "  UUID: ${UUID:0:8}..."
    print_info "  Argo域名: $ARGO_DOMAIN"
    print_info "  订阅路径: $SUB_PATH"
}

# 安装 Cloud Foundry CLI
install_cf_cli() {
    if ! command_exists cf; then
        print_info "Installing Cloud Foundry CLI..."
        wget -q -O - https://packages.cloudfoundry.org/debian/cli.cloudfoundry.org.key | sudo apt-key add -
        echo "deb https://packages.cloudfoundry.org/debian stable main" | sudo tee /etc/apt/sources.list.d/cloudfoundry-cli.list
        sudo apt-get update
        sudo apt-get install -y cf8-cli
        if [ $? -eq 0 ]; then
            print_success "Cloud Foundry CLI installed successfully"
        else
            print_error "Failed to install Cloud Foundry CLI"
            exit 1
        fi
    else
        print_info "Cloud Foundry CLI is already installed"
    fi
}

# 登录到 Cloud Foundry
login_to_cf() {
    print_info "Logging into Cloud Foundry at $API_ENDPOINT..."
    cf login -a $API_ENDPOINT -u "$EMAIL" -p "$PASSWORD"
    
    if [ $? -eq 0 ]; then
        print_success "Successfully logged into Cloud Foundry"
    else
        print_error "Failed to login to Cloud Foundry"
        exit 1
    fi
}

# 设置目标组织和空间
set_target() {
    print_info "Setting target organization and space..."
    
    # 获取当前目标组织
    CURRENT_ORG=$(cf target | grep "org:" | awk '{print $2}')
    
    if [ -n "$CURRENT_ORG" ]; then
        ORG="$CURRENT_ORG"
        print_info "Using current organization: $ORG"
    else
        print_error "Could not determine current organization"
        exit 1
    fi
    
    # 获取当前目标空间
    CURRENT_SPACE=$(cf target | grep "space:" | awk '{print $2}')
    
    if [ -n "$CURRENT_SPACE" ] && [ "$CURRENT_SPACE" != "No" ]; then
        SPACE="$CURRENT_SPACE"
        print_info "Using current space: $SPACE"
    else
        print_warning "No space targeted, will create or select a space"
        SPACE=""
    fi
}

# 检查并创建空间（如果不存在）
check_and_create_space() {
    if [ -z "$SPACE" ]; then
        print_info "No space targeted, checking available spaces..."
        
        # 获取所有空间
        SPACES=$(cf spaces | tail -n +4 | head -n -1 | awk '{print $1}')
        
        if [ -z "$SPACES" ]; then
            print_warning "No spaces found, creating a new space..."
            SPACE="dev-$(date +%s)"
            cf create-space "$SPACE"
            
            if [ $? -eq 0 ]; then
                print_success "Space '$SPACE' created successfully"
            else
                print_error "Failed to create space '$SPACE'"
                exit 1
            fi
        else
            # 使用第一个可用空间
            SPACE=$(echo "$SPACES" | head -n 1)
            print_info "Using existing space: $SPACE"
        fi
        
        # 设置目标空间
        cf target -s "$SPACE"
        if [ $? -ne 0 ]; then
            print_error "Failed to target space '$SPACE'"
            exit 1
        fi
    else
        print_info "Space '$SPACE' already exists"
    fi
}

# 克隆项目
clone_project() {
    print_info "Cloning nodejs-argo project..."
    
    if [ -d "nodejs-argo" ]; then
        print_warning "nodejs-argo directory already exists, removing it..."
        rm -rf nodejs-argo
    fi
    
    git clone https://github.com/eooce/nodejs-argo.git
    if [ $? -eq 0 ]; then
        print_success "Project cloned successfully"
    else
        print_error "Failed to clone project"
        exit 1
    fi
    
    cd nodejs-argo
}

# 创建 manifest.yml 文件
create_manifest() {
    # 生成随机应用名
    APP_NAME=$(generate_app_name)
    print_info "Generated random application name: $APP_NAME"
    
    print_info "Creating manifest.yml file..."
    
    cat > manifest.yml << EOF
applications:
- name: $APP_NAME
  memory: 512M
  disk_quota: 512M
  instances: 1
  buildpacks:
  - nodejs_buildpack
  command: npm start
  health-check-type: port
  timeout: 180
  env:
    NAME: SAP
    UUID: $UUID
    ARGO_PORT: "$ARGO_PORT"
    ARGO_DOMAIN: $ARGO_DOMAIN
    ARGO_AUTH: $ARGO_AUTH
    SUB_PATH: $SUB_PATH
    CFIP: $CFIP
    CFPORT: "$CFPORT"
EOF
    
    print_success "manifest.yml file created with application name: $APP_NAME"
}

# 部署应用
deploy_app() {
    print_info "Deploying application..."
    
    cf push
    
    if [ $? -eq 0 ]; then
        print_success "Application deployed successfully"
    else
        print_error "Failed to deploy application"
        exit 1
    fi
}

# 显示部署信息
show_deployment_info() {
    print_info "Getting deployment information..."
    
    # 获取应用路由
    ROUTE=$(cf app $APP_NAME | grep "routes:" | awk '{print $2}')
    
    if [ -n "$ROUTE" ]; then
        print_success "Application URL: https://$ROUTE"
        print_info "Subscription URL: https://$ROUTE/$SUB_PATH"
    else
        print_warning "Could not retrieve application URL"
    fi
    
    print_info "Application name: $APP_NAME"
    print_info "Organization: $ORG"
    print_info "Space: $SPACE"
    print_info "Region: $REGION"
    print_info "API Endpoint: $API_ENDPOINT"
}

# 主函数
main() {
    print_info "Starting deployment process for nodejs-argo to SAP Cloud Foundry..."
    
    # 解析命令行参数
    parse_arguments "$@"
    
    # 安装 Cloud Foundry CLI
    install_cf_cli
    
    # 登录到 Cloud Foundry
    login_to_cf
    
    # 设置目标组织和空间
    set_target
    
    # 检查并创建空间（如果不存在）
    check_and_create_space
    
    # 克隆项目
    clone_project
    
    # 创建 manifest.yml 文件
    create_manifest
    
    # 部署应用
    deploy_app
    
    # 显示部署信息
    show_deployment_info
    
    print_success "Deployment completed successfully!"
}

# 执行主函数
main "$@"
