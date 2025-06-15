# PolRoute-DS-with-hive

Este projeto tem como objetivo demonstrar o uso do Apache Hive como ferramenta de Data Warehouse para análise de dados relacionados a segurança pública, utilizando um conjunto de dados de crimes. A solução é construída sobre um ambiente Docker, o que facilita a replicação e portabilidade da configuração.

## HiveServer2

Fonte: [https://hub.docker.com/r/apache/hive](https://hub.docker.com/r/apache/hive)

A página informa que a imagem inclui uma instalação do Apache Hive, um sistema de data warehouse baseado no Hadoop que permite executar consultas SQL (usando HiveQL) em grandes volumes de dados distribuídos.

O comando inicializa o HiveServer2 — um serviço que aceita conexões via JDBC/ODBC para executar consultas HiveQL — junto com um Metastore incorporado na mesma instância. Dessa forma, tudo funciona dentro de um único container, sem precisar configurar um banco de dados separado para o Metastore.

Para rodar o container, execute:

```bash
docker run -d -p 10000:10000 -p 10002:10002 --env SERVICE_NAME=hiveserver2 --name hive4 apache/hive:${HIVE_VERSION}
```

Acesse o Beeline dentro do container:

```bash
docker exec -it hive4 beeline -u 'jdbc:hive2://localhost:10000/'
```
Acesse o HiveServer2 Web UI no navegador em  `http://localhost:10002/`.

## Load CSV para Apache Hive no container Docker

Premissas:

- O arquivo CSV está disponível localmente.
- O CSV possui cabeçalho na primeira linha.

1. Copie o arquivo CSV para o container

```bash
docker cp arquivo.csv hive4:/tmp/arquivo.csv
```
2. Conecte-se ao Hive via Beeline

```bash
docker exec -it hive4 beeline -u 'jdbc:hive2://localhost:10000/'
```
3. Crie o schema PolRouteDS 

```bash
CREATE DATABASE IF NOT EXISTS PolRouteDS;
```

4. Crie as tabelas no schema PolRouteDS

```bash
CREATE TABLE PolRouteDS.crime_data (
  id INT,
  total_feminicide INT,
  total_homicide INT,
  total_felony_murder INT,
  total_bodily_harm INT,
  total_theft_cellphone INT,
  total_armed_robbery_cellphone INT,
  total_theft_auto INT,
  total_armed_robbery_auto INT,
  segment_id INT,
  time_id INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ';'
STORED AS TEXTFILE;
```
5. Carregue os dados do CSV para a tabela

```bash
LOAD DATA LOCAL INPATH '/tmp/crime.csv' INTO TABLE PolRouteDS.crime_data;
```

6. Verifique os dados carregados
```bash
SELECT * FROM PolRouteDS.crime_data LIMIT 10;
```

