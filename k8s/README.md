# Kubernetes部署指南

本目录包含Running App的完整Kubernetes部署配置。

## 📁 文件说明

| 文件 | 说明 |
|------|------|
| `namespace.yaml` | 命名空间定义 |
| `configmap.yaml` | 应用配置（非敏感） |
| `secret.yaml` | 敏感配置（密码、密钥） |
| `pvc.yaml` | 持久化存储声明 |
| `mysql.yaml` | MySQL数据库 |
| `redis.yaml` | Redis缓存 |
| `deployment.yaml` | API服务部署 |
| `ingress.yaml` | 入口配置（HTTPS） |
| `hpa.yaml` | 水平自动扩缩容 |

## 🚀 部署步骤

### 1. 创建命名空间

```bash
kubectl apply -f namespace.yaml
```

### 2. 配置Secret（重要！）

**编辑 `secret.yaml`**，替换所有敏感信息：

```yaml
DB_PASSWORD: "your_secure_password"
JWT_SECRET: "your_jwt_secret_at_least_32_characters"
SMS_ACCESS_KEY_ID: "your_sms_key"
SMS_ACCESS_KEY_SECRET: "your_sms_secret"
```

或使用命令行创建：

```bash
kubectl create secret generic running-app-secret \
  --from-literal=DB_PASSWORD='your_password' \
  --from-literal=JWT_SECRET='your_jwt_secret' \
  -n running-app
```

应用配置：

```bash
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
```

### 3. 创建存储

```bash
kubectl apply -f pvc.yaml
```

### 4. 部署数据库和缓存

```bash
kubectl apply -f mysql.yaml
kubectl apply -f redis.yaml
```

等待数据库和Redis就绪：

```bash
kubectl wait --for=condition=ready pod -l app=mysql -n running-app --timeout=300s
kubectl wait --for=condition=ready pod -l app=redis -n running-app --timeout=300s
```

### 5. 初始化数据库

进入MySQL Pod执行初始化：

```bash
# 获取MySQL Pod名称
kubectl get pods -n running-app -l app=mysql

# 进入Pod
kubectl exec -it mysql-0 -n running-app -- bash

# 连接MySQL
mysql -u root -p
# 输入密码

# 导入数据库结构
mysql> use running_app;
mysql> source /path/to/schema.sql;
```

或从外部导入：

```bash
kubectl cp backend/database/running_app.sql running-app/mysql-0:/tmp/
kubectl exec -it mysql-0 -n running-app -- mysql -u root -p running_app < /tmp/running_app.sql
```

### 6. 部署API服务

```bash
kubectl apply -f deployment.yaml
```

### 7. 配置Ingress（域名访问）

**编辑 `ingress.yaml`**，修改域名：

```yaml
spec:
  tls:
  - hosts:
    - api.your-domain.com  # 修改为你的域名
  rules:
  - host: api.your-domain.com  # 修改为你的域名
```

应用配置：

```bash
kubectl apply -f ingress.yaml
```

### 8. 启用自动扩缩容（可选）

```bash
kubectl apply -f hpa.yaml
```

## 📊 监控和管理

### 查看所有资源

```bash
kubectl get all -n running-app
```

### 查看Pod状态

```bash
kubectl get pods -n running-app
```

### 查看日志

```bash
# 查看API日志
kubectl logs -f deployment/running-app-api -n running-app

# 查看最近的日志
kubectl logs --tail=100 -f deployment/running-app-api -n running-app

# 查看特定Pod日志
kubectl logs -f pod/running-app-api-xxx -n running-app
```

### 进入容器

```bash
kubectl exec -it deployment/running-app-api -n running-app -- bash
```

### 查看服务状态

```bash
kubectl get svc -n running-app
```

### 查看Ingress状态

```bash
kubectl get ingress -n running-app
kubectl describe ingress running-app-ingress -n running-app
```

## 🔧 配置管理

### 更新ConfigMap

```bash
kubectl edit configmap running-app-config -n running-app
```

### 更新Secret

```bash
kubectl edit secret running-app-secret -n running-app
```

### 滚动更新

```bash
# 更新镜像
kubectl set image deployment/running-app-api api=running-app/api:v1.6.0 -n running-app

# 查看滚动更新状态
kubectl rollout status deployment/running-app-api -n running-app

# 回滚
kubectl rollout undo deployment/running-app-api -n running-app

# 查看历史版本
kubectl rollout history deployment/running-app-api -n running-app
```

### 扩缩容

```bash
# 手动扩容
kubectl scale deployment running-app-api --replicas=5 -n running-app

# 查看扩缩容状态
kubectl get hpa -n running-app
```

## 🔍 故障排查

### 1. Pod无法启动

```bash
# 查看Pod事件
kubectl describe pod running-app-api-xxx -n running-app

# 查看日志
kubectl logs running-app-api-xxx -n running-app

# 查看上一个容器的日志（如果Pod重启了）
kubectl logs running-app-api-xxx -n running-app --previous
```

### 2. 健康检查失败

```bash
# 手动测试健康检查
kubectl exec -it deployment/running-app-api -n running-app -- curl http://localhost/health
```

### 3. 数据库连接失败

```bash
# 检查MySQL是否运行
kubectl get pods -l app=mysql -n running-app

# 测试数据库连接
kubectl exec -it mysql-0 -n running-app -- mysql -u root -p -e "SELECT 1"

# 检查网络连通性
kubectl exec -it deployment/running-app-api -n running-app -- nc -zv mysql-service 3306
```

### 4. 存储问题

```bash
# 查看PVC状态
kubectl get pvc -n running-app

# 查看PV状态
kubectl get pv
```

## 🛡️ 安全建议

1. **不要将secret.yaml提交到Git**
   ```bash
   # 添加到.gitignore
   echo "k8s/secret.yaml" >> .gitignore
   ```

2. **使用加密的Secret存储**
   - 使用Sealed Secrets
   - 使用外部密钥管理（AWS KMS、HashiCorp Vault等）

3. **启用RBAC**
   - 限制服务账户权限
   - 使用最小权限原则

4. **网络策略**
   - 限制Pod之间的网络访问
   - 只允许必要的通信

5. **镜像安全**
   - 使用私有镜像仓库
   - 扫描镜像漏洞
   - 使用特定版本标签，避免使用latest

## 📈 性能优化

### 资源请求和限制

根据实际使用情况调整 `deployment.yaml` 中的资源配置：

```yaml
resources:
  requests:
    cpu: 200m        # 根据实际调整
    memory: 512Mi    # 根据实际调整
  limits:
    cpu: 1000m       # 根据实际调整
    memory: 1Gi      # 根据实际调整
```

### HPA配置

调整 `hpa.yaml` 中的扩缩容参数：

```yaml
minReplicas: 3      # 最小副本数
maxReplicas: 10     # 最大副本数
targetCPUUtilizationPercentage: 70  # CPU目标使用率
```

## 🌐 外部访问

### 使用LoadBalancer（云环境）

```yaml
apiVersion: v1
kind: Service
metadata:
  name: running-app-api-lb
  namespace: running-app
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: running-app
    component: api
```

### 使用NodePort（本地环境）

```yaml
spec:
  type: NodePort
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
```

## 📝 备份

### 数据库备份

```bash
# 导出数据库
kubectl exec mysql-0 -n running-app -- mysqldump -u root -p running_app > backup.sql

# 恢复数据库
kubectl exec -i mysql-0 -n running-app -- mysql -u root -p running_app < backup.sql
```

### 文件备份

```bash
# 备份上传文件
kubectl cp running-app/running-app-api-xxx:/var/www/html/public/uploads ./uploads-backup
```

## 🔄 完整部署命令

```bash
# 一键部署所有资源
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f pvc.yaml
kubectl apply -f mysql.yaml
kubectl apply -f redis.yaml
kubectl apply -f deployment.yaml
kubectl apply -f ingress.yaml
kubectl apply -f hpa.yaml

# 等待所有Pod就绪
kubectl wait --for=condition=ready pod --all -n running-app --timeout=600s
```

## 📞 支持

如有问题，请查看：
- [Kubernetes官方文档](https://kubernetes.io/docs/)
- [Running App部署文档](../DEPLOYMENT.md)
- [运维监控指南](../OPERATIONS_GUIDE.md)

---

**版本**: 1.0
**最后更新**: 2024-11-17
**维护**: Running App DevOps Team
