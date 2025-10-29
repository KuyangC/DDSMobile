import React from 'react';
import { View, Text, StyleSheet, ScrollView, Dimensions } from 'react-native';

const { width: screenWidth } = Dimensions.get('window');

const AreaTable = () => {
  // Generate 63 data dengan distribusi yang diminta
  const generateContainers = () => {
    const containers = [];
    
    // Container 1: 1-10
    containers.push(Array.from({ length: 10 }, (_, i) => i + 1));
    // Container 2: 11-20
    containers.push(Array.from({ length: 10 }, (_, i) => i + 11));
    // Container 3: 21-30
    containers.push(Array.from({ length: 10 }, (_, i) => i + 21));
    // Container 4: 31-40
    containers.push(Array.from({ length: 10 }, (_, i) => i + 31));
    // Container 5: 41-50
    containers.push(Array.from({ length: 10 }, (_, i) => i + 41));
    // Container 6: 51-60
    containers.push(Array.from({ length: 10 }, (_, i) => i + 51));
    // Container 7: 61-63
    containers.push(Array.from({ length: 3 }, (_, i) => i + 61));
    
    return containers;
  };

  const containers = generateContainers();

  const renderTable = (data: number[]) => (
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
      {data.map((number) => (
        <View key={number} style={styles.row}>
          <View style={[styles.cell, styles.hashCell]}><Text style={styles.boldText}>{number}</Text></View>
          <View style={[styles.cell, styles.areaCell]}><Text style={styles.boldText}>LANTAI BSMNT</Text></View>
          <View style={styles.cell}></View>
          <View style={styles.cell}></View>
          <View style={styles.cell}></View>
          <View style={styles.cell}></View>
          <View style={styles.cell}></View>
          <View style={styles.cell}></View>
        </View>
      ))}
    </View>
  );

  return (
    <ScrollView 
      style={styles.scrollContainer}
      contentContainerStyle={styles.contentContainer}
      showsVerticalScrollIndicator={true}
    >
      {/* Baris 1: Container 1-2 */}
      <View style={styles.horizontalRow}>
        <View style={styles.containerWrapper}>
          {renderTable(containers[0])}
        </View>
        <View style={styles.containerWrapper}>
          {renderTable(containers[1])}
        </View>
      </View>

      {/* Baris 2: Container 3-4 */}
      <View style={styles.horizontalRow}>
        <View style={styles.containerWrapper}>
          {renderTable(containers[2])}
        </View>
        <View style={styles.containerWrapper}>
          {renderTable(containers[3])}
        </View>
      </View>

      {/* Baris 3: Container 5-6 */}
      <View style={styles.horizontalRow}>
        <View style={styles.containerWrapper}>
          {renderTable(containers[4])}
        </View>
        <View style={styles.containerWrapper}>
          {renderTable(containers[5])}
        </View>
      </View>

      {/* Baris 4: Container 7 */}
      <View style={styles.horizontalRow}>
        <View style={styles.containerWrapper}>
          {renderTable(containers[6])}
        </View>
        <View style={styles.containerWrapper}>
          {/* Container kosong untuk balance layout */}
        </View>
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
    height: 25,
    borderBottomWidth: 1,
    borderBottomColor: '#000',
  },
  cell: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    borderRightWidth: 1,
    borderRightColor: '#000',
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
});

export default AreaTable;