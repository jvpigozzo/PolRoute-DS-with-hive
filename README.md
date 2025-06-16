# PolRoute-DS-with-hive

Este projeto tem como objetivo demonstrar o uso do Apache Hive como ferramenta de Data Warehouse para análise de dados relacionados à segurança pública, utilizando um conjunto de dados de datas. A solução é construída sobre um ambiente Docker, o que facilita a replicação e portabilidade da configuração.

## HiveServer2

Fonte: [https://hub.docker.com/r/apache/hive](https://hub.docker.com/r/apache/hive)

A imagem inclui uma instalação do Apache Hive, um sistema de data warehouse baseado no Hadoop que permite executar consultas SQL (usando HiveQL) em grandes volumes de dados distribuídos.

O comando inicializa o HiveServer2 — um serviço que aceita conexões via JDBC/ODBC para executar consultas HiveQL — junto com um Metastore incorporado na mesma instância. Dessa forma, tudo funciona dentro de um único container, sem precisar configurar um banco de dados separado para o Metastore.

Para rodar o container, execute:

```bash
docker run -d -p 10000:10000 -p 10002:10002 --env SERVICE_NAME=hiveserver2 --name hive4 apache/hive:${HIVE_VERSION}
```

Acesse o Beeline dentro do container:

```bash
docker exec -it hive4 beeline -u 'jdbc:hive2://localhost:10000/'
```

Acesse o HiveServer2 Web UI no navegador em `http://localhost:10002/`.

## Carregar CSV no Apache Hive (via container Docker)

### Premissas

- O arquivo CSV está disponível localmente.
- O CSV possui cabeçalho na primeira linha (que deve ser ignorado no carregamento).

### Etapas

1. **Remova o cabeçalho do CSV localmente**:

```bash
tail -n +2 data.csv > data_no_header.csv
```

2. **Copie o CSV (sem cabeçalho) para o container**:

```bash
docker cp data_no_header.csv hive4:/tmp/data.csv
```

3. **Conecte-se ao Hive via Beeline**:

```bash
docker exec -it hive4 beeline -u 'jdbc:hive2://localhost:10000/'
```

4. **Crie o schema `PolRouteDS`**:

```sql
CREATE DATABASE IF NOT EXISTS PolRouteDS;
```

5. **Crie a tabela `data_data` no schema**:

```sql
CREATE TABLE PolRouteDS.data (
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

6. **Carregue os dados do CSV para a tabela Hive**:

```sql
LOAD DATA LOCAL INPATH '/tmp/data.csv' INTO TABLE PolRouteDS.data_data;
```

7. **Verifique os dados carregados**:

```sql
SELECT * FROM PolRouteDS.data_data LIMIT 10;
```
