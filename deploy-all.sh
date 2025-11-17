#!/bin/bash

# Running App 一键部署脚本
# 部署后端、Android、iOS所有组件

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 显示欢迎信息
clear
echo -e "${BLUE}"
echo "╔══════════════════════════════════════════╗"
echo "║                                          ║"
echo "║        Running App 一键部署脚本          ║"
echo "║              v1.5.9                      ║"
echo "║                                          ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# 显示菜单
echo -e "${YELLOW}请选择要部署的组件:${NC}"
echo "  1. 后端 (Backend)"
echo "  2. Android"
echo "  3. iOS"
echo "  4. 全部"
echo "  5. 退出"
echo ""
read -p "请输入选项 [1-5]: " choice

case $choice in
    1)
        echo -e "\n${GREEN}开始部署后端...${NC}"
        cd backend
        chmod +x deploy.sh
        ./deploy.sh
        ;;
    2)
        echo -e "\n${GREEN}开始构建Android...${NC}"
        cd android
        echo -e "${YELLOW}配置API地址:${NC}"
        echo "  编辑文件: app/src/main/java/com/runningapp/di/AppModule.kt"
        echo "  修改第130行的baseUrl"
        echo ""
        read -p "是否已配置API地址? (y/n): " configured
        if [ "$configured" != "y" ]; then
            echo -e "${RED}请先配置API地址后再构建${NC}"
            exit 1
        fi
        echo -e "${YELLOW}开始构建APK...${NC}"
        ./gradlew assembleDebug
        echo -e "${GREEN}✓ APK构建完成${NC}"
        echo -e "  输出: android/app/build/outputs/apk/debug/app-debug.apk"
        ;;
    3)
        echo -e "\n${GREEN}开始构建iOS...${NC}"
        cd ios
        echo -e "${YELLOW}配置API地址:${NC}"
        echo "  编辑文件: RunningApp/Services/NetworkService.swift"
        echo "  修改第8行的baseURL"
        echo ""
        read -p "是否已配置API地址? (y/n): " configured
        if [ "$configured" != "y" ]; then
            echo -e "${RED}请先配置API地址后再构建${NC}"
            exit 1
        fi
        echo -e "${YELLOW}安装CocoaPods依赖...${NC}"
        pod install
        echo -e "${GREEN}✓ 依赖安装完成${NC}"
        echo -e "  使用Xcode打开: ios/RunningApp.xcworkspace"
        ;;
    4)
        echo -e "\n${GREEN}开始全部部署...${NC}"

        # 后端
        echo -e "\n${BLUE}=== 部署后端 ===${NC}"
        cd backend
        chmod +x deploy.sh
        ./deploy.sh
        cd ..

        # Android
        echo -e "\n${BLUE}=== 构建Android ===${NC}"
        echo -e "${YELLOW}请确保已配置API地址${NC}"
        read -p "继续? (y/n): " continue_android
        if [ "$continue_android" == "y" ]; then
            cd android
            ./gradlew assembleDebug
            cd ..
            echo -e "${GREEN}✓ Android构建完成${NC}"
        fi

        # iOS
        echo -e "\n${BLUE}=== 准备iOS ===${NC}"
        echo -e "${YELLOW}请确保已配置API地址${NC}"
        read -p "继续? (y/n): " continue_ios
        if [ "$continue_ios" == "y" ]; then
            cd ios
            pod install
            cd ..
            echo -e "${GREEN}✓ iOS准备完成${NC}"
        fi

        echo -e "\n${GREEN}========================================${NC}"
        echo -e "${GREEN}全部部署完成！${NC}"
        echo -e "${GREEN}========================================${NC}"
        ;;
    5)
        echo -e "${YELLOW}退出部署${NC}"
        exit 0
        ;;
    *)
        echo -e "${RED}无效的选项${NC}"
        exit 1
        ;;
esac

echo -e "\n${GREEN}部署完成！${NC}"
echo -e "\n${YELLOW}下一步:${NC}"
echo -e "  1. 查看 QUICK_START.md 快速开始指南"
echo -e "  2. 查看 INTEGRATION_GUIDE.md 集成第三方服务"
echo -e "  3. 查看 API_CONFIG.md 配置API地址"
echo ""
