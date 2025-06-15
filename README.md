# PolRoute-DS-with-hive

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

Copie o arquivo CSV para um diretório acessível dentro do container:

```bash
docker cp arquivo.csv hive4:/tmp/arquivo.csv
```

Conecte-se ao Hive usando o Beeline e no prompt do Beeline, crie a tabela Hive que representa o schema do CSV, informando o delimitador.

Ainda no Beeline, rode o comando para carregar os dados:

```bash
LOAD DATA LOCAL INPATH '/tmp/crime.csv' INTO TABLE crime_data;
```

