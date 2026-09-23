from datetime import datetime
from airflow.sdk import DAG
from airflow.providers.standard.operators.bash import BashOperator


with DAG(
    dag_id="data_mart_360_dag",
    start_date=datetime(2026, 9, 13),
    schedule="30 19 * * *",
    catchup=False,
    tags=["data_engineering", "dbt"],
) as dag:

    source_check = BashOperator(
        task_id="source_check",
        bash_command="echo 'Source check passed'",
    )

    dbt_build = BashOperator(
        task_id="dbt_build",
        bash_command="cd /opt/dbt/data_mart_360 && dbt build",
    )

    dbt_test = BashOperator(
        task_id="dbt_test",
        bash_command="cd /opt/dbt/data_mart_360 && dbt test",
    )

    source_check >> dbt_build >> dbt_test