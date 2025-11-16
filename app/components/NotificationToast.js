import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, Animated, TouchableOpacity } from 'react-native';
import { Poppins_500Medium, Poppins_600SemiBold, useFonts } from '@expo-google-fonts/poppins';
import * as Haptics from 'expo-haptics';

const NotificationToast = ({
  visible,
  type,
  title,
  message,
  duration = 3000,
  onHide
}) => {
  let [fontsLoaded] = useFonts({
    Poppins_500Medium,
    Poppins_600SemiBold
  });

  const [fadeAnim] = useState(new Animated.Value(0));
  const [translateY] = useState(new Animated.Value(-100));

  useEffect(() => {
    if (visible && fontsLoaded) {
      // Haptic feedback based on notification type
      const triggerHaptic = async () => {
        try {
          switch (type) {
            case 'success':
              await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
              break;
            case 'error':
              await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
              break;
            case 'warning':
              await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Warning);
              break;
            case 'info':
            default:
              await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
              break;
          }
        } catch (error) {
          console.warn('Haptic feedback failed:', error);
        }
      };

      triggerHaptic();

      // Show notification
      Animated.parallel([
        Animated.timing(fadeAnim, {
          toValue: 1,
          duration: 300,
          useNativeDriver: true,
        }),
        Animated.timing(translateY, {
          toValue: 0,
          duration: 300,
          useNativeDriver: true,
        })
      ]).start();

      // Auto hide after duration
      const timer = setTimeout(() => {
        hideNotification();
      }, duration);

      return () => clearTimeout(timer);
    }
  }, [visible, fontsLoaded, type]);

  const hideNotification = () => {
    Animated.parallel([
      Animated.timing(fadeAnim, {
        toValue: 0,
        duration: 300,
        useNativeDriver: true,
      }),
      Animated.timing(translateY, {
        toValue: -100,
        duration: 300,
        useNativeDriver: true,
      })
    ]).start(() => {
      onHide?.();
    });
  };

  if (!visible || !fontsLoaded) {
    return null;
  }

  const getNotificationStyle = (type) => {
    switch (type) {
      case 'success':
        return {
          backgroundColor: '#11B653',
          icon: '✅'
        };
      case 'error':
        return {
          backgroundColor: '#FF3B30',
          icon: '❌'
        };
      case 'warning':
        return {
          backgroundColor: '#FF9500',
          icon: '⚠️'
        };
      case 'info':
      default:
        return {
          backgroundColor: '#007AFF',
          icon: 'ℹ️'
        };
    }
  };

  const notificationStyle = getNotificationStyle(type);

  return (
    <View style={styles.container}>
      <TouchableOpacity
        activeOpacity={0.9}
        onPress={hideNotification}
        style={styles.touchableArea}
      >
        <Animated.View
          style={[
            styles.notification,
            {
              backgroundColor: notificationStyle.backgroundColor,
              opacity: fadeAnim,
              transform: [{ translateY }]
            }
          ]}
        >
          <View style={styles.content}>
            <Text style={styles.icon}>{notificationStyle.icon}</Text>
            <View style={styles.textContainer}>
              <Text style={styles.title}>{title}</Text>
              <Text style={styles.message}>{message}</Text>
            </View>
          </View>
          <TouchableOpacity onPress={hideNotification} style={styles.closeButton}>
            <Text style={styles.closeButtonText}>×</Text>
          </TouchableOpacity>
        </Animated.View>
      </TouchableOpacity>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    position: 'absolute',
    top: 50,
    left: 20,
    right: 20,
    zIndex: 9999,
  },
  touchableArea: {
    width: '100%',
  },
  notification: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    borderRadius: 12,
    shadowColor: '#000',
    shadowOffset: {
      width: 0,
      height: 2,
    },
    shadowOpacity: 0.25,
    shadowRadius: 3.84,
    elevation: 5,
    minHeight: 60,
  },
  content: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
  },
  icon: {
    fontSize: 20,
    marginRight: 12,
  },
  textContainer: {
    flex: 1,
  },
  title: {
    fontSize: 14,
    fontFamily: 'Poppins_600SemiBold',
    color: '#fff',
    marginBottom: 2,
  },
  message: {
    fontSize: 12,
    fontFamily: 'Poppins_500Medium',
    color: '#fff',
    opacity: 0.9,
  },
  closeButton: {
    marginLeft: 12,
    padding: 4,
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  closeButtonText: {
    fontSize: 16,
    fontFamily: 'Poppins_600SemiBold',
    color: '#fff',
    lineHeight: 16,
  },
});

export default NotificationToast;