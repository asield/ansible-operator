# Koios Automation — despliegue con Kustomize

Este repositorio despliega **una instancia de Koios Automation** en Kubernetes con
`kubectl` y Kustomize: el operador Koios y una plataforma (`KoiosPlatform`) con su
gateway, su UI y su controller.

Koios es una distribución comunitaria construida desde el código abierto de AWX,
Jewel (gateway de plataforma) y ansible-ui, con la arquitectura de Ansible Automation
Platform como referencia. No incluye ni redistribuye imágenes ni software de Red Hat
AAP.

## Qué se despliega

```
namespace awx
├── operador Koios (Deployment awx-operator-controller-manager)
└── KoiosPlatform koios
    ├── PostgreSQL compartido (bases gateway y controller) y Redis
    ├── gateway (Jewel + Envoy) con la UI
    └── controller (CR AWX hijo: web, task, migraciones)
```

El operador vigila solo su propio namespace. Todo el tráfico entra por el gateway:
la UI en `/`, la API del gateway en `/api/gateway/` y la del controller en
`/api/controller/`.

| Imagen | Repositorio | Versión | Digest |
|---|---|---|---|
| Operador | `quay.io/koios/koios-operator` | `2026.10.0` | `sha256:8743fd5d9fd8…` |
| Controller (AWX) | `quay.io/koios/koios-awx` | `2026.10.0` | `sha256:3fee6e11ed74…` |
| Gateway (Jewel) | `quay.io/koios/koios-jewel` | `2026.10.0` | `sha256:2793e6fc51b5…` |
| UI | `quay.io/koios/koios-ui` | `2026.10.0` | `sha256:7519bcc92e6f…` |
| Execution environment | `quay.io/koios/koios-ee` | `2026.10.0` | `sha256:2515ab5e7202…` |

Cada imagen lleva además la etiqueta `src-<commit>` de su código fuente. Los digests
completos están en [docs/versions.md](docs/versions.md).

PostgreSQL 15 (`quay.io/sclorg/postgresql-15-c9s`), Redis (`docker.io/library/redis`)
y Envoy (`docker.io/envoyproxy/envoy`) se usan desde su origen, fijados por digest.
El operador fija todas las imágenes por digest; cada una puede sustituirse en el spec
(`spec.controller.image`, `spec.gateway.image`, `spec.ui.image`, …) o, para entornos
sin acceso a Internet, con las variables `RELATED_IMAGE_KOIOS_*` del Deployment del
operador (ver [docs/operations.md](docs/operations.md#imágenes-y-entornos-desconectados)).

> **Estado:** primera versión, `2026.10.0`. Las imágenes de `quay.io/koios` son
> públicas. PostgreSQL externo aún no está soportado.

## Estructura

| Ruta | Contenido |
|---|---|
| `operator/` | CRDs, RBAC y Deployment del operador (generados por `hack/render-operator.sh`) |
| `components/private-registry/` | Opcional: pull secret `koios-quay-pull` para un registro privado o espejo |
| `instance/base/` | La `KoiosPlatform` `koios` |
| `instance/overlays/internal/` | Sin exposición (port-forward o tráfico interno) |
| `instance/overlays/ingress/` | Ingress con TLS en el borde |
| `instance/overlays/loadbalancer/` | Service LoadBalancer |
| `examples/k3d/` | Clúster local completo en k3d |
| `docs/operations.md` | Acceso, backup y restore, actualización, borrado |

## Requisitos

- Kubernetes 1.29 o superior y `kubectl` 1.27 o superior (Kustomize integrado).
- Una StorageClass por defecto (o `spec.database.storage_class`).
- Para `ingress`: un controlador de Ingress y, si se usa TLS, el Secret del certificado.
- Unos 4 CPU y 8 GiB de memoria libres para una instancia.

## Inicio rápido en k3d

```sh
k3d cluster create --config examples/k3d/cluster.yaml
kubectl config use-context k3d-koios        # o usa --context en cada orden

# 1. Operador (crea el namespace awx).
kubectl apply --server-side -k examples/k3d/operator
kubectl -n awx rollout status deploy/awx-operator-controller-manager

# 2. Plataforma.
kubectl apply --server-side -k examples/k3d/platform
kubectl -n awx wait koiosplatform/koios --for=condition=Successful --timeout=20m
```

Después abre <http://koios.localhost:8080> y entra como `admin` con la contraseña de:

```sh
kubectl -n awx get secret koios-admin-password -o jsonpath='{.data.password}' | base64 -d; echo
```


## Instalación en un clúster

1. **Operador**:

   ```sh
   kubectl apply --server-side -k 'https://github.com/asield/ansible-operator//operator?ref=main'
   kubectl -n awx rollout status deploy/awx-operator-controller-manager
   ```

2. **Plataforma**: crea un overlay propio a partir de `instance/overlays/ingress` (o
   `internal`, `loadbalancer`), cambia `hostname`, `public_base_url`, `ingress_class` y
   `tls_secret`, y aplícalo con `kubectl apply --server-side -k <overlay>`. Espera a la
   condición `Successful` (de 5 a 15 minutos según el clúster).

Para un registro privado o espejo: crea el Secret `koios-quay-pull`
(`kubernetes.io/dockerconfigjson`) en `awx`, añade `components/private-registry` a los
dos overlays y fija las imágenes con `RELATED_IMAGE_KOIOS_*`
([docs/operations.md](docs/operations.md#imágenes-y-entornos-desconectados)).

`public_base_url` debe ser la URL con la que los usuarios llegan al gateway.

## Personalización

El spec completo está en la CRD (`kubectl explain koiosplatform.spec`). Lo más habitual:

| Campo | Para qué |
|---|---|
| `spec.database.storage_size`, `storage_class` | Volumen de PostgreSQL |
| `spec.gateway.replicas` | Réplicas del gateway |
| `spec.controller.*` | Cualquier campo del CR AWX (réplicas, recursos, EE adicionales, imágenes); la plataforma fija solo base de datos, prefijo de API y exposición |
| `spec.ui.enabled` | Servir o no la UI |
| `spec.image_pull_secrets` | Pull secrets para todas las cargas |

## Comprobación

```sh
kubectl -n awx get koiosplatform koios
kubectl -n awx get pods
curl -s http://koios.localhost:8080/api/gateway/v1/ping/
curl -s http://koios.localhost:8080/api/controller/v2/ping/
```

## Licencia

Apache-2.0 ([LICENSE](LICENSE)). Avisos de terceros en [NOTICE](NOTICE). Las
imágenes llevan las licencias de sus componentes en `/licenses/koios/`.
