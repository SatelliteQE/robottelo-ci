# pip install -r requirements.txt

DATA_PATH="${HOME}/satellite_performance_data.csv"

if [ ! -f ${DATA_PATH} ]; then
   touch ${DATA_PATH}
fi

./performance_report.py --data-path ${DATA_PATH} ${OS} ${BUILD_LABEL} JUNIT
