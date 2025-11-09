import React from 'react';
import { View, Text, StyleSheet, ScrollView, ActivityIndicator } from 'react-native';
import useSlaveData from '../../hooks/useSlaveData';

// Helper function to determine cell styles based on slave status
const getStatusStyle = (status: string) => {
  switch (status) {
    case 'ALARM':
      return { backgroundColor: '#ff4d4d', color: 'white' }; // Red
    case 'TROUBLE':
      return { backgroundColor: '#ffc107', color: 'black' }; // Yellow
    case 'NORMAL':
      return { backgroundColor: '#28a745', color: 'white' }; // Green
    case 'OFFLINE':
    default:
      return { backgroundColor: '#6c757d', color: 'white' }; // Gray
  }
};

// Zone and Bell indicators
const ZoneIndicator = ({ active, status, style }: { active: boolean; status: string; style: any }) => (
  <View style={[styles.cell, style]}>
    {active && <View style={[styles.indicator, getStatusStyle(status)]} />}
  </View>
);

const AreaTable = () => {
  const { slaveData, loading, error } = useSlaveData();

  // The main render function for a single table of slaves
  const renderTable = (slaveNumbers: number[]) => {
    const slaves = slaveNumbers.map((num: number) => (slaveData.slaves as any)[num]).filter(Boolean);

    return (
      <View style={styles.tableContainer}>
        {/* Header */}
        <View style={styles.row}>
          <View style={[styles.cell, styles.hashCell]}><Text style={styles.boldText}>#</Text></View>
          <View style={[styles.cell, styles.areaCell]}><Text style={styles.boldText}>AREA</Text></View>
          <View style={styles.cell}><Text style={styles.boldText}>1</Text></View>
          <View style={styles.cell}><Text style={styles.boldText}>2</Text></View>
          <View style={styles.cell}><Text style={styles.boldText}>3</Text></View>
          <View style={styles.cell}><Text style={styles.boldText}>4</Text></View>
          <View style={styles.cell}><Text style={styles.boldText}>5</Text></View>
          <View style={styles.cell}><Text style={styles.boldText}>B</Text></View>
        </View>

        {/* Data Rows */}
        {slaves.map((slave: any) => {
          const isAlarm = slave.status === 'ALARM';
          const isTrouble = slave.status === 'TROUBLE';

          return (
            <View key={slave.address} style={styles.row}>
              <View style={[styles.cell, styles.hashCell]}>
                <Text style={styles.boldText}>{slave.address}</Text>
              </View>
              <View style={[styles.cell, styles.areaCell]}>
                <Text style={styles.boldText}>{`Area ${slave.address}`}</Text>
              </View>
              {[1, 2, 3, 4, 5].map(zoneNum => {
                const isZoneActive = (isAlarm && slave.alarm_zones?.includes(zoneNum)) || (isTrouble && slave.trouble_zones?.includes(zoneNum));
                
                let cellBackgroundColor;
                // If the whole slave is NORMAL or OFFLINE, all zones share that color.
                if (slave.status === 'NORMAL' || slave.status === 'OFFLINE') {
                  cellBackgroundColor = getStatusStyle(slave.status).backgroundColor;
                } else {
                  // Otherwise, color the specific zone based on its own status.
                  cellBackgroundColor = isZoneActive
                    ? getStatusStyle(slave.status).backgroundColor // Red for ALARM, Yellow for TROUBLE
                    : getStatusStyle('NORMAL').backgroundColor;   // Green for non-active zones
                }

                return (
                  <ZoneIndicator
                    key={zoneNum}
                    active={isZoneActive}
                    status={slave.status}
                    style={{ backgroundColor: cellBackgroundColor }}
                  />
                );
              })}
              <ZoneIndicator 
                active={false} // Disabled for now as per request
                status={slave.status} 
                style={{}} // No style
              />
            </View>
          );
        })}
      </View>
    );
  };

  if (loading && !(slaveData.slaves as any)[1]) { // Show loading only on initial fetch
    return <ActivityIndicator size="large" color="#0000ff" style={{ flex: 1, justifyContent: 'center' }} />;
  }

  if (error) {
    return <Text style={styles.errorText}>Error loading data: {(error as Error)?.message || 'Unknown error'}</Text>;
  }

  // Define the slave numbers for each of the 7 tables
  const containers = [
    Array.from({ length: 10 }, (_, i) => i + 1),  // 1-10
    Array.from({ length: 10 }, (_, i) => i + 11), // 11-20
    Array.from({ length: 10 }, (_, i) => i + 21), // 21-30
    Array.from({ length: 10 }, (_, i) => i + 31), // 31-40
    Array.from({ length: 10 }, (_, i) => i + 41), // 41-50
    Array.from({ length: 10 }, (_, i) => i + 51), // 51-60
    Array.from({ length: 3 }, (_, i) => i + 61),  // 61-63
  ];

  return (
    <ScrollView
      style={styles.scrollContainer}
      contentContainerStyle={styles.contentContainer}
      showsVerticalScrollIndicator={true}
    >
      <View style={styles.horizontalRow}>
        <View style={styles.containerWrapper}>{renderTable(containers[0])}</View>
        <View style={styles.containerWrapper}>{renderTable(containers[1])}</View>
      </View>
      <View style={styles.horizontalRow}>
        <View style={styles.containerWrapper}>{renderTable(containers[2])}</View>
        <View style={styles.containerWrapper}>{renderTable(containers[3])}</View>
      </View>
      <View style={styles.horizontalRow}>
        <View style={styles.containerWrapper}>{renderTable(containers[4])}</View>
        <View style={styles.containerWrapper}>{renderTable(containers[5])}</View>
      </View>
      <View style={styles.horizontalRow}>
        <View style={styles.containerWrapper}>{renderTable(containers[6])}</View>
        <View style={styles.containerWrapper} />
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  scrollContainer: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  contentContainer: {
    paddingVertical: 10,
    paddingHorizontal: 10,
  },
  horizontalRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 15,
    marginBottom: 15,
  },
  containerWrapper: {
    flex: 1,
  },
  tableContainer: {
    flex: 1,
    borderWidth: 1,
    borderColor: '#000',
    backgroundColor: '#fff',
  },
  row: {
    flexDirection: 'row',
    minHeight: 25,
    borderBottomWidth: 1,
    borderBottomColor: '#000',
    alignItems: 'stretch',
  },
  cell: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    borderRightWidth: 1,
    borderRightColor: '#000',
    paddingVertical: 4,
  },
  hashCell: {
    flex: 0.5,
  },
  areaCell: {
    flex: 2.5,
    alignItems: 'flex-start',
    paddingLeft: 8,
  },
  boldText: {
    fontWeight: 'bold',
    fontSize: 10,
  },
  indicator: {
    width: 12,
    height: 12,
    borderRadius: 6,
  },
  errorText: {
    color: 'red',
    textAlign: 'center',
    marginTop: 20,
  },
});

export default AreaTable;
