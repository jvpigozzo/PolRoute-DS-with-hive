# PolRoute-DS-with-hive

### Launch the HiveServer2 with an embedded Metastore

Fonte: [https://hub.docker.com/r/apache/hive](https://hub.docker.com/r/apache/hive)

A página informa que a imagem contém uma instalação do Apache Hive, um sistema de data warehouse construído sobre o Hadoop, que facilita consultas SQL (via HiveQL) em grandes volumes de dados distribuídos.

O comando inicia o HiveServer2 — serviço que aceita conexões via JDBC/ODBC para rodar queries HiveQL — junto com um Metastore embutido na mesma instância. Tudo roda em um único container, sem a necessidade de configurar um banco de dados separado para o Metastore.

Para rodar o container, execute:

```bash
docker run -d -p 10000:10000 -p 10002:10002 --env SERVICE_NAME=hiveserver2 --name hive4 apache/hive:${HIVE_VERSION}
```

Usage
Acessando o Beeline dentro do container:

```bash
docker exec -it hive4 beeline -u 'jdbc:hive2://localhost:10000/'
```
Acesse o HiveServer2 Web UI no navegador em  `http://localhost:10002/`.
