# casino-frontend

SPA Angular 17 del casino VidalCasino, servida por **nginx-unprivileged** en el
puerto interno **8080**. Es el único servicio expuesto a Internet mediante un
Service tipo LoadBalancer en EKS. Enruta todas las llamadas `/api/*` por DNS
interno del clúster hacia los backends correspondientes — nunca apunta a IPs
directas.

---

## Estructura del repositorio

\```
frontend_intro_devops_casino/
├── src/                        # Código fuente Angular
├── k8s/
│   ├── frontend-deployment.yaml
│   ├── frontend-service.yaml   # tipo LoadBalancer (URL pública)
│   └── frontend-hpa.yaml
├── .github/
│   └── workflows/
│       └── deploy-frontend.yml
├── default.conf.template       # Configuración nginx con rutas por servicio
├── .dockerignore
├── .gitignore
├── Dockerfile                  # Multi-stage: build Angular + nginx-unprivileged
├── angular.json
├── package.json
└── README.md
\```

---

## Enrutamiento nginx → backends

| Prefijo | Destino (DNS interno del clúster) |
|---------|----------------------------------|
| `/api/auth/` | `casino-backend:3000` |
| `/api/usuarios/` | `casino-backend:3000` |
| `/api/juegos/` | `casino-backend:3000` |
| `/api/transacciones/` | `casino-backend:3000` |
| `/api/bonos/` | `bonos-service:8004` |
| `/api/apuestas/` | `apuestas-service:8005` |
| `/api/estadisticas/` | `estadisticas-service:8006` |
| `/livez` | nginx propio (200 directo) |

---

## Cómo construir

### Local (sin Docker)

\```bash
npm install
npm start       # http://localhost:4200
\```

### Con Docker

\```bash
docker build -t casino-frontend:local .
docker run -p 8080:8080 casino-frontend:local
curl http://localhost:8080/livez
\```

---

## Cómo desplegar

### Pipeline automático (recomendado)

\```bash
# Despliegue a rama deploy
git push origin deploy

# Release con versión semántica
git tag v1.2.3
git push origin v1.2.3
\```

### Manual en EKS

\```bash
aws eks update-kubeconfig --name <CLUSTER_NAME> --region <AWS_REGION>
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml
kubectl apply -f k8s/frontend-hpa.yaml

# Obtener URL pública
kubectl get service frontend -o jsonpath='{.status.loadBalancer.ingress.hostname}'
\```

---

## GitHub Secrets requeridos

| Secret | Descripción |
|--------|-------------|
| `AWS_ACCESS_KEY_ID` | Credencial temporal AWS Academy |
| `AWS_SECRET_ACCESS_KEY` | Credencial temporal AWS Academy |
| `AWS_SESSION_TOKEN` | Token de sesión temporal AWS Academy |
| `AWS_REGION` | Región AWS (ej. `us-east-1`) |
| `ECR_REPOSITORY` | `casino-frontend` |
| `EKS_CLUSTER` | Nombre del clúster EKS |

---

## Autoescalado (HPA)

El HPA escala entre **2 y 6 réplicas** con umbral de **50% CPU**.

\```bash
kubectl get hpa frontend-hpa -w
\```

---

## Comandos útiles

\```bash
# Ver pods
kubectl get pods -l app=frontend

# Ver logs en tiempo real
kubectl logs -f deployment/frontend

# Obtener URL pública del LoadBalancer
kubectl get service frontend

# Ver uso de recursos
kubectl top pods -l app=frontend

# Forzar rollout
kubectl rollout restart deployment/frontend
\```

---

## Troubleshooting

### Pantalla en blanco o error 502 en `/api/*`
Verificar que los Services de los backends estén corriendo:
\```bash
kubectl get services
kubectl get pods
\```

### `/livez` no responde
El pod no levantó. Revisar logs:
\```bash
kubectl logs <nombre-del-pod>
kubectl describe pod <nombre-del-pod>
\```

### URL del LoadBalancer no aparece
El ELB tarda 1-2 minutos en provisionarse tras el primer `kubectl apply`:
\```bash
kubectl get service frontend -w
\```

---

## Convención de commits

\```
feat:  nueva funcionalidad
fix:   corrección de bug
chore: mantenimiento
ci:    cambios en pipeline
docs:  cambios en documentación
\```
