# Real-Time Logistics Insights Platform

An end-to-end, data engineering project that streams simulated GPS & sensor events, lands them in a data lake/warehouse, transforms them into a star schema, and serves insights via an API and dashboard. The stack emphasizes data generation, ingestion, big-data processing, containerization, CI/CD, monitoring, testing, messaging systems, data serving, and security.

---

## ✨ Highlights

* **End-to-end**: Generator → Kafka → S3/Postgres → Spark → dbt → FastAPI/Streamlit
* **Batch + Real-time**: Kafka streams + daily Spark jobs
* **Best-practice lake**: Bronze/Silver/Gold (Parquet) with data quality gates
* **Production touches**: CI/CD, Prometheus/Grafana monitoring, secrets management, RBAC

---

## 📐 Architecture



**Security**: TLS for Kafka, SASL/ACLs, S3 SSE, Postgres RBAC, secrets via .env/Vault
**Testing**: Pytest (generators/utils), Great Expectations (Bronze→Silver), dbt tests (Gold)
**CI/CD**: GitHub Actions → build images, run tests, deploy Compose
**Resilience**: DLQ + retries for malformed events

---

## 🧰 Tech Stack

* **Messaging**: Apache Kafka, Kafka Connect, Schema Registry
* **Storage**: Amazon S3/MinIO (lake), PostgreSQL (OLTP)
* **Processing**: Apache Spark (batch & optional streaming), dbt (warehouse modeling)
* **Orchestration**: Apache Airflow
* **Serving**: FastAPI (REST), Streamlit (BI)
* **Quality & Testing**: Great Expectations, dbt tests, pytest
* **Monitoring**: Prometheus, Grafana
* **Security**: TLS/SASL for Kafka, RBAC, IAM/SSE for S3, env-based secrets
* **DevOps**: Docker & Docker Compose, GitHub Actions CI/CD

---

## 🗂️ Repository Structure

```
.
├── docker-compose.yml
├── .env.example
├── airflow/
│   ├── dags/
│   │   ├── batch_daily_curate.py
│   │   └── streaming_health_check.py
│   └── requirements.txt
├── generators/
│   ├── producer_gps.py
│   ├── producer_fuel.py
│   └── common/
│       └── schemas.py
├── kafka/
│   ├── connect/
│   │   ├── s3_sink.json
│   │   └── jdbc_sink.json
│   └── configs/
│       └── server.properties
├── spark/
│   ├── jobs/
│   │   ├── bronze_to_silver.py
│   │   └── silver_to_gold.py
│   └── requirements.txt
├── dbt/
│   ├── profiles-example.yml
│   ├── dbt_project.yml
│   └── models/
│       ├── staging/
│       └── marts/
│           ├── dim_driver.sql
│           ├── dim_route.sql
│           └── fact_deliveries.sql
├── ge/  # Great Expectations
│   ├── expectations/
│   └── checkpoints/
├── serving/
│   ├── api/fastapi_app.py
│   └── bi/app.py  # Streamlit
├── monitoring/
│   ├── prometheus.yml
│   └── grafana_dashboards/
├── tests/
│   ├── test_generators.py
│   └── test_utils.py
└── README.md
```

---

## ⚡ Quick Start (Docker Compose)

**Prereqs**: Docker Desktop, Git, Python 3.10+

1. **Clone & configure**

```bash
git clone https://github.com/<you>/real-time-logistics-insights.git
cd real-time-logistics-insights
cp .env.example .env  # update passwords, S3 keys (or MinIO), etc.
```

2. **Bring up the stack**

```bash
docker compose up -d --build
```

Services started: Kafka, Schema Registry, Kafka Connect, Postgres, MinIO/S3, Airflow (webserver/scheduler), Spark, Prometheus, Grafana, FastAPI, Streamlit.

3. **Seed connectors**

```bash
# Post Kafka Connect configs
curl -X POST localhost:8083/connectors -H 'Content-Type: application/json' \
  -d @kafka/connect/s3_sink.json
curl -X POST localhost:8083/connectors -H 'Content-Type: application/json' \
  -d @kafka/connect/jdbc_sink.json
```

4. **Start data generators**

```bash
python generators/producer_gps.py
python generators/producer_fuel.py
```

5. **Open UIs**

* Airflow: [http://localhost:8080](http://localhost:8080)  (user/pass in `.env`)
* Grafana: [http://localhost:3000](http://localhost:3000)
* Streamlit: [http://localhost:8501](http://localhost:8501)
* FastAPI docs: [http://localhost:8000/docs](http://localhost:8000/docs)
* MinIO console (if used): [http://localhost:9001](http://localhost:9001)

---

## 🔐 Environment (.env)

```
# Kafka
KAFKA_BROKERS=broker:29092
KAFKA_SECURITY_PROTOCOL=SASL_SSL
KAFKA_SASL_MECHANISM=SCRAM-SHA-512
KAFKA_SASL_USERNAME=appuser
KAFKA_SASL_PASSWORD=change_me

# S3 / MinIO
S3_ENDPOINT=http://minio:9000
S3_ACCESS_KEY=minioadmin
S3_SECRET_KEY=minioadmin
S3_BUCKET=smartmove-bronze

# Postgres
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=smartmove

# Airflow
AIRFLOW__CORE__FERNET_KEY=generate_me
AIRFLOW__WEBSERVER__RBAC=True
AIRFLOW_ADMIN_USER=airflow
AIRFLOW_ADMIN_PASSWORD=airflow
```

> Never commit real secrets. Use Docker/compose secrets or Vault in production.

---

## 🧪 Testing & Data Quality

* **pytest**: `pytest -q` for unit tests on generators/utilities
* **Great Expectations**: run checkpoints in Airflow between Bronze→Silver
* **dbt tests**: `dbt test` on Gold models (not null, unique, referential integrity)

Example GE validation step (pseudocode):

```python
from great_expectations.checkpoint import SimpleCheckpoint
SimpleCheckpoint(name="bronze_to_silver", data_context=context, validations=[...]).run()
```

---

## 🛠️ Orchestration (Airflow)

Key DAGs:

* `batch_daily_curate`: schedules Spark **bronze→silver→gold** jobs, runs GE, then `dbt run + dbt test`.
* `streaming_health_check`: monitors Kafka consumer lag and posts metrics for Grafana alerts.

Trigger manually from the UI or let the schedule run.

---

## 🧮 Warehouse Models (dbt)

* **Gold star schema**

  * `fact_deliveries` (one row per delivery)
  * `dim_driver`, `dim_vehicle`, `dim_route`, `dim_hub`
* **KPIs** shown in Streamlit/REST:

  * Avg delivery delay by region/hub
  * On-time % by route/driver
  * Fuel burn per km & anomalies
  * Route efficiency (km vs planned)

---

## 📊 Monitoring

* **Prometheus exporters**: Airflow, Kafka, Spark
* **Grafana dashboards**: prebuilt panels for

  * Kafka consumer lag
  * DAG duration & task failures
  * Spark job runtime & input rows
* **Alerts**: example rules for high lag or repeated DAG failures

---

## 🚀 CI/CD (GitHub Actions)

Sample workflow (simplified):

```yaml
name: ci
on: [push, pull_request]
jobs:
  build-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: actions/setup-python@v5
        with: { python-version: '3.10' }
      - run: pip install -r spark/requirements.txt -r airflow/requirements.txt
      - run: pytest -q
      - run: dbt deps && dbt compile
  images:
    runs-on: ubuntu-latest
    needs: build-test
    steps:
      - uses: actions/checkout@v4
      - uses: docker/login-action@v3
        with: { username: ${{ secrets.DOCKERHUB_USERNAME }}, password: ${{ secrets.DOCKERHUB_TOKEN }} }
      - run: docker compose build
      - run: docker compose push
```

Add a deploy job if you publish this stack to a VM or cloud.

---

## 🔒 Security

* **Kafka**: enable TLS, SASL (SCRAM) and topic ACLs for producers/consumers
* **S3**: SSE (encryption at rest), scoped access keys or IAM roles
* **Postgres**: role-based users, least privilege, periodic backups
* **Secrets**: `.env` for local; Vault/Parameter Store for real deployments
* **Audit**: log admin actions and data access where possible

---

## 🧑‍🏫 Demo Script (2–3 mins)

1. Show the **architecture diagram** in README.
2. Start **producers** and show **Kafka messages** (kcat/console consumer).
3. Open **Airflow**: kick off `batch_daily_curate` → watch GE/dbt steps.
4. Open **Streamlit**: highlight KPIs; filter by region/driver.
5. Open **Grafana**: point to Kafka lag & DAG runtime panels.
6. Close with **GitHub Actions** run passing & images built.

---

## 🧭 Roadmap

* Add **CDC** with Debezium (Postgres → Kafka) for operational change streams
* Add **OpenMetadata/Amundsen** for data catalog
* Add **feature store** (Hopsworks/Feast) for ML features from Gold
* Deploy **cloud variant** on AWS (MSK, EMR/Glue, S3, ECS/EKS)

---

## ❓ FAQ

**Q:** Can I run without cloud accounts?
**A:** Yes—use MinIO for S3, all services are containerized.

**Q:** Do I need GPUs?
**A:** No. CPU-only is fine for this workload.

**Q:** Where do I find sample data?
**A:** Generators create it; you can also seed historical CSVs into Bronze.

---

## 📝 License

MIT (or your preferred license).

---

## 🙏 Acknowledgements

Inspired by best practices from modern data stacks and open-source ecosystems: Apache Kafka, Spark, Airflow, dbt, Great Expectations, Prometheus/Grafana.
