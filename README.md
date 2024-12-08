![](./imagenes/Banner%20ORT.jpg)

# ORT-FI-8184-DevOps 2024S2-G6-AMARTINEZ

 Agustín Martinez - 274479
 Tutor: Federico Barceló

## Índice

- [Presentación del problema](#presentación-del-problema)
- [Solución propuesta](#solución-propuesta)
  - [Herramientas utilizadas](#herramientas-utilizadas)
  - [Planificación](#planificación)
  - [Repositorio de código](#repositorio-de-código)
    - [Estrategia de ramas](#estrategia-ramas)
    - [Repositorio microservicios](#repositorio-microservicios)
    - [Repositorio frontend](#repositorio-frontend)
    - [Repositorio devops](#repositorio-devops)
  - [Workflow CI/CD](#workflow-cicd)
    - [CI/CD microservicios](#cicd-microservicios)
    - [CI/CD frontend](#cicd-frontend)
    - [Infraestructura como código](#infraestructura-como-código)
  - [Test automatizados](#test-automatizados)
  - [Análisis de código](#análisis-de-código)

---

## Presentación del problema
Describe aquí el problema que busca resolver tu proyecto. Incluye contexto, motivaciones y cualquier dato relevante.

---

## Solución propuesta
Explica la solución planteada para abordar el problema, incluyendo las principales características y beneficios.

### Herramientas utilizadas
Listado de herramientas y tecnologías utilizados en el proyecto:

- **Herramienta de Versionado**: GitHub 
- **Herramienta de CI/CD**: GitHub Actions 
- **Aplicativo de FE a buildear y desplegar**: React 
- **Herramienta para análisis de código estático**: SonarCloud 
- **Herramienta para análisis de prueba extra**: JUnit & Mockito
- **Cloud provider**: AWS 
- **Orquestador**: AWS ECS 
- **Servicio serverless a usar**: API Gateway
- **Herramienta para el IaC**: Terraform


### Planificación

Se decidió utilizar un tablero Kanban en Jira para la planificación y seguimiento de las tareas. Con esto logré tener una visualización clara y sencilla del flujo de trabajo. Además contaba con la flexibilidad necesaria para poder agregar, modificar y eliminar tareas a medida que iba avanzando con la implementación.

A continuación se muestran algunas imágenes a modo de evidencia de lo que fue la evolución del tablero.

![](./imagenes/Tablero%20Kanban/Tablero%20Kanban%201.png)

![](./imagenes/Tablero%20Kanban/Tablero%20Kanban%202.png)

![](./imagenes/Tablero%20Kanban/Tablero%20Kanban%203.png)

---

## Repositorio de código
Como se mencionó anteriormente, GitHub fue la herramienta elegida como repositorio de código. Esta decisión fue tomada basandome en mi experiencia con la herramienta, su amplía adopción en la industría y la practicidad de utilizar GitHub Actions, herramienta la cual fue enseñada en el curso.

### Estrategia de ramas
Tanto para los repositorios de microservicios como para el del frontend se decide utilizar la estrategia de ramas GitFlow. En estos repositorios se definen 4 ramas principales las cuales son master, staging y dev. De esta forma tendremos la rama master por un lado, que apunta a ser una rama estable la cual está lista para producción en cualquier momento y la rama staging en donde ocurrirá la preparación de nuevas versiones. Además, existirán ramas específicas por cada característica a desarrollar (feature branch), esto aporta flexibilidad a los desarrolladores al momento de colaborar sin interferir entre sí.

![](./imagenes/GitHub/GitFlow.png)

**Evidencia Git Flow**

![](./imagenes/GitHub/Evidencia%20Repo%20Back.png)

---

Para el repositorio de DevOps se utiliza la estrategia de trunk-based. Debido a que este repositorio contendrá configuraciones de infraestructura y scripts de automatización, los cambios serán pequeños, incrementales y requerirán una rápida validación en los entornos de integración y producción. Con la estrategia de trunk-based fomentamos la agilidad, con commits frecuentes e integración continua, evitando largas ramas que pueden llegar a retrasar la implementación de nuevos cambios.

![](./imagenes/GitHub/Trunk-Based.png)

**Evidencia Trunk-Based**

![](./imagenes/GitHub/Evidencia%20Repo%20Devops.png)

### Repositorio microservicios
El repositorio de microservicios es un monorepo, esto quiere decir que contiene dentro del mismo, los 4 microservicios a desplegar. Además se incluye el archivo necesario para el flujo de CICD.

### Repositorio frontend
Este repositorio contiene la aplicación del frontend seleccionada. Como se mencionó anteriormente, esta es la de react, específicamente la aplicación de "catalog". Además incluye el archivo necesario para el flujo de CICD.

### Repositorio devops
En este repositorio se pueden encontrar principalmente dos cosas. Por un lado tenemos los archivos correspondientes a los flujos de CICD, tanto del repositorio de microservicios como el de frontend. Además de los archivos de terraform necesarios para desplegar toda la infraestructura como código. 

---

## Workflow CI/CD
Describe los flujos de integración y despliegue continuo del proyecto.

### CI/CD frontend

El workflow implementado para el repositorio de la aplicación frontend se dispara cada vez que se realiza un push a las ramas de dev, staging o master. Al ocurrir esto, el flujo genera un trigger hacia el repositorio de devops, pasándole datos importantes como el repositorio y la rama sobre la que se hizo el push, así como también el hash del commit realizado. 

El workflow en el repositorio devops se encarga de realizar las siguientes tareas:

En primer lugar está la tarea “Build and Analyze Frontend Application”, esta tarea realiza el checkout del código con los datos que le fueron proporcionados por el trigger, configura nodejs para así poder realizar la instalación de dependencias de la aplicación frontend y luego construirla. Por último se realiza un análisis sobre la calidad y seguridad del código utilizando la herramienta SonarCloud.

La segunda tarea es “Deploy Infrastructure as Code”, esta tarea se ejecuta únicamente si la tarea anterior finaliza correctamente. Se encarga de realizar un checkout de la rama master del repositorio de devops para así obtener los archivos de terraform necesarios, configura las credenciales para conectarse con AWS, las mismas las obtiene accediendo a los secrets configurados en la organización. Por último se posiciona en el directorio donde se encuentra la configuración de terraform correspondiente al frontend y ejecuta los comandos de terraform init y terraform apply para aplicar el despliegue de la infraestructura necesaria.

La última tarea es la de “Deploy Frontend to S3” y al igual que la anterior, esta tarea se ejecuta únicamente si la anterior finaliza correctamente y sin ningún error. Nuevamente configura las credenciales de AWS basándose en los secrets de la organización y ejecuta el comando necesario para sincronizar la aplicación de frontend al bucket S3 desplegado en el paso anterior. Cabe aclarar que se utiliza un artifact de GitHub para acceder al build de la aplicación generado en la primera tarea.


### CI/CD microservicios

El workflow implementado para el repositorio de los microservicios se dispara cada vez que se realiza un push a las ramas de dev, staging o master. Al ocurrir esto, el flujo genera un trigger hacia el repositorio de devops, pasándole datos importantes como el repositorio y la rama sobre la que se hizo el push, así como también el hash del commit realizado y una lista de los microservicios a desplegar. 

El workflow en el repositorio devops se encarga de realizar las siguientes tareas:

En primer lugar está la tarea de “Build, Test, and Analyze Microservices”, esta tarea realiza el checkout del código con los datos que le fueron proporcionados por el trigger. Configura Java para poder ejecutar Maven y procede a realizar tanto la compilación como el análisis de los microservicios. Por cada microservicio recibido desde el trigger en la lista, ejecuta los test correspondientes, esto compila y ejecuta las pruebas implementadas, luego realiza el análisis del código con SonarCloud.

La segunda tarea es “Publish Images DockerHub”, esta tarea se ejecuta únicamente si la tarea anterior finaliza correctamente. Lo primero que se hace es recuperar el artifact empaquetado en el paso anterior, se autentica en DockerHub utilizando los secrets correspondientes en la organización y comienza a construir las imagenes. Por cada microservicio en la lista, genera un tag basándose en la rama y el commit, construye la imagen y sube la misma al repositorio de DockerHub.

Por último está la tarea de “Deploy Infrastructure as Code”, al igual que la tarea anterior, esta solo se ejecuta si el paso anterior finaliza exitosamente. Comienza realizando un checkout del repositorio de devops para obtener los archivos necesarios de terraform, y configura las credenciales de AWS, utilizando los secrets de la organización. Luego se posiciona en el directorio donde se encuentra la configuración de terraform correspondiente al backend y ejecuta los comandos de terraform init y terraform apply, esto despliega la infraestructura necesaria con las imágenes de los microservicios actualizadas.


### Infraestructura como código
Describe cómo se administra la infraestructura:
- Tecnologías utilizadas (ejemplo: Terraform, Ansible).
- Despliegues automatizados.

---

## Test automatizados
Describe las estrategias de testing utilizadas:
- Unitarios.
- Integración.
- End-to-End (E2E).

---

## Análisis de código
Detalla las herramientas de análisis estático o dinámico utilizadas:
- Ejemplo: SonarQube, ESLint.
- Reglas y configuraciones aplicadas.

---
