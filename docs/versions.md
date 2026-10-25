# Versiones

## 2026.10.0

| Imagen | Referencia | Fuente |
|---|---|---|
| Operador | `quay.io/koios/koios-operator@sha256:8743fd5d9fd8845b7316dd12a0723be0ba06baa3d896946cc295fd1729a532c1` | operador Koios `08f55651af7a589ac3451949e2311b5b41dc067a` (derivado de `ansible/awx-operator`) |
| Controller (AWX) | `quay.io/koios/koios-awx@sha256:3fee6e11ed7401094670ea3df2a9bd53bcd9551e5ac72a94b1b5518e3526a5b3` | `ansible/awx` `6fc51b6d25b5bf3ad7efa66cc4e62bdb27177027` |
| Gateway (Jewel) | `quay.io/koios/koios-jewel@sha256:2793e6fc51b51cc714ff6d086fd350898ae4e0adb98545269c3679bca9cdac43` | `ansible/jewel` `5e34446ce4acbd6d32a4c549d223ba5f0b340f0e` |
| UI | `quay.io/koios/koios-ui@sha256:7519bcc92e6f45ce4184249ba6d5f02a5ba1497f92a1baf7318bb759d30aaa36` | `ansible/ansible-ui` `da1eaf4acbc496ec46efe7813ce7ee55486f597b` |
| Execution environment | `quay.io/koios/koios-ee@sha256:2515ab5e72020166c13d5767df2f4399f2d5ffcabe19f7ba04e8114bbde5c661` | receta `ansible/awx-ee` `b8da0081e74e5db40b86f4c97c81cdc725980e58` |
| PostgreSQL 15 | `quay.io/sclorg/postgresql-15-c9s@sha256:ac1ac9aa8ba2ef0bf312beee2b713dc2386fb179176137d11019009a52903ad4` | upstream, sin cambios |
| Redis | `docker.io/library/redis@sha256:44960b3100c48159a66d28c18b0588c193492e25f7551d60e51dd464fc3eca5b` | upstream, sin cambios |
| Envoy | `docker.io/envoyproxy/envoy@sha256:e97e7ae2d35bb40359de68eeea2d1546295b6ce6626dcd94c36963a96d0f855c` | upstream, sin cambios |

Análisis de seguridad de la publicación (Trivy 0.58.1, HIGH/CRITICAL): sin secretos;
vulnerabilidades conocidas en dependencias de las versiones fijadas (Python, Go y, en el
operador, paquetes de la imagen base). Se corrigen actualizando esas dependencias en
versiones siguientes.
