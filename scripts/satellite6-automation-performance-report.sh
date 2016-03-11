pip install -r requirements.txt

if [ ! -f ~/satellite_performance_data.csv ]; then
   touch ~/satellite_performance_data.csv
fi

./performance_report.py ${OS} ${BUILD_LABEL} ${JUNIT}
