# KlipperApp Backend

Este es el backend de la aplicación KlipperApp, desarrollado en Ruby on Rails.

## Requisitos previos

Asegúrate de tener instalados los siguientes componentes en tu sistema:

- **Docker**: Para contenedores.
- **Docker Compose**: Para orquestar los servicios.

## Instrucciones de instalación

Sigue estos pasos para configurar y ejecutar el proyecto en tu entorno local:

### 1. Clonar el repositorio

Clona este repositorio en tu máquina local:

```bash
git clone https://github.com/tu-usuario/klipperapp-be.git
cd klipperapp-be
docker-compose build
docker-compose up
docker-compose run web rails db:migrate