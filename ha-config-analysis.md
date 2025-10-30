# Home Assistant Configuration Analysis

## ✅ GOOD - Working Correctly

### 1. MQTT Sensors
- All have proper `state_class: measurement` ✓
- Device classes are correct ✓
- Unique IDs present ✓

### 2. Template Sensors
- Cost calculations look correct ✓
- Proper use of `float(0)` defaults ✓
- Units are appropriate ✓

### 3. Utility Meters
- Sources are properly defined ✓
- Cycles configured correctly ✓

## ⚠️ ISSUES FOUND

### 1. **CRITICAL: Recorder Include/Exclude Conflict**

**Problem:**
```yaml
recorder:
  exclude: !include recorder_exclude.yaml
  include:
    domains:
      - sensor    # ← This includes ALL sensors
```

When you specify `domains: sensor`, it includes **ALL sensors**, which then conflicts with your specific entity list below. This is redundant and potentially confusing.

**Two Options to Fix:**

**Option A - Remove domain, keep specific entities (Recommended):**
```yaml
recorder:
  purge_keep_days: 60
  auto_purge: true
  exclude: !include recorder_exclude.yaml
  include:
    # Remove the domains section entirely
    entities:
      - sensor.daily_sonoff_energy
      # ... rest of your entities
```

**Option B - Use domain + entity_globs (Simpler):**
```yaml
recorder:
  purge_keep_days: 60
  auto_purge: true
  exclude: !include recorder_exclude.yaml
  include:
    domains:
      - sensor
      - input_number
      - switch
      - binary_sensor
      - light
    # No need for entities list if you include the whole domain
```

### 2. **Missing Pi5 Sensor Entities**

In your recorder include list, you have:
```yaml
- sensor.pi5_temperature          # ← Wrong/old sensor
- sensor.pi5_sensor_humidity      # ← Correct
```

**Should be:**
```yaml
- sensor.pi5_sensor_temperature   # ← Your new MQTT sensor
- sensor.pi5_sensor_humidity      # ← Already there
- sensor.pi5_sensor_battery       # ← Missing
```

### 3. **BLE Monitor vs MQTT Sensors**

You have:
- `ble_monitor` for Balcony & Freezer sensors
- MQTT for Pi5 sensor (via our bridge)

These reference different sensors, but your recorder includes:
```yaml
- sensor.xiaomi_temperature       # ← Which Xiaomi sensor is this?
- sensor.xiaomi_humidity
- sensor.xiaomi_battery_voltage
```

**Check:** Are these from `ble_monitor`? The entities should be named like:
- `sensor.balcony_temperature_humidity_temperature`
- `sensor.freezer_temperature_humidity_temperature`

Or similar. Verify the actual entity names in Developer Tools → States.

### 4. **Database Configuration Commented Out**

```yaml
# db_url: mysql://ha_user:Falcon1959@192.168.50.243/homeassistant?charset=utf8mb4
#  db_url: mysql+pymysql://ha_user:Falcon1959@192.168.50.243/homeassistant?charset=utf8mb4
```

**Questions:**
- Are you using the default SQLite database?
- If you want MySQL/MariaDB (recommended for 60 days of history), you should uncomment one of these
- The second line (pymysql) is the correct modern syntax

**To use MySQL (optional but recommended):**
1. Set up MariaDB on your Pi5
2. Uncomment: `db_url: mysql+pymysql://ha_user:Falcon1959@192.168.50.243/homeassistant?charset=utf8mb4`
3. Restart HA

### 5. **Raspberry Pi GPU Temperature**

```yaml
- sensor.raspberry_pi_gpu_temperature
```

This sensor might not exist on some systems. Verify it exists in Developer Tools → States.

### 6. **State Class on Template Sensors**

Your cost/energy template sensors use `state_class: total`, which is **correct** for cumulative values.

However, some "Rest of House" calculations might go negative, which causes issues with `total` state class.

**Example Issue:**
If your calculation goes negative (which can happen):
```yaml
state_class: total  # ← Will cause errors with negative values
```

**Fix for Rest of House sensors:**
```yaml
state_class: measurement  # ← Better for calculated values
```

Or add a max() filter:
```yaml
state: >
  {{ [0, (
      (states('sensor.daily_sonoff_energy')  | float(0))
    - (states('sensor.daily_geyser_energy')  | float(0))
    - (states('sensor.daily_pc_energy')      | float(0))
    - (states('sensor.daily_apple_energy')   | float(0))
  )] | max | round(3) }}
```

## 🔍 RECOMMENDATIONS

### 1. **Simplify Recorder Configuration**

Since you're including entire domains, the specific entity list is redundant.

**Recommended configuration:**
```yaml
recorder:
  db_url: mysql+pymysql://ha_user:Falcon1959@192.168.50.243/homeassistant?charset=utf8mb4
  purge_keep_days: 60
  auto_purge: true
  exclude: !include recorder_exclude.yaml
  include:
    domains:
      - sensor
      - input_number
      - switch
      - binary_sensor
      - light
    entity_globs:
      - sensor.*_energy
      - sensor.*_cost
      - sensor.*_speed
      - sensor.pi5_sensor_*
      - sensor.*temperature*
      - sensor.*humidity*
```

### 2. **Add Friendly Names**

Consider adding friendly names to your sensors via `customize.yaml` for better dashboard display.

### 3. **Verify Entity Names**

Run this in Developer Tools → Template:
```yaml
{% for state in states.sensor %}
  {% if 'xiaomi' in state.entity_id.lower() or 'pi5' in state.entity_id.lower() %}
    - {{ state.entity_id }}
  {% endif %}
{% endfor %}
```

This will show all your Xiaomi and Pi5 sensor entity names.

### 4. **Add Comments**

Your YAML is well-organized, but consider adding more comments for sections, especially in the template calculations.

## 📋 SUMMARY OF REQUIRED CHANGES

### Immediate Fixes:

1. **Update recorder entity list:**
   ```yaml
   # Remove:
   - sensor.pi5_temperature
   
   # Add:
   - sensor.pi5_sensor_temperature
   - sensor.pi5_sensor_battery
   ```

2. **Verify Xiaomi sensor names** in Developer Tools

3. **Consider database migration** to MySQL for better performance with 60 days of data

### Optional Improvements:

1. Simplify recorder to use only domains + entity_globs
2. Add negative value protection to "Rest of House" calculations
3. Verify GPU temperature sensor exists

## 🧪 How to Test

1. Go to Developer Tools → Check Configuration
2. Fix any errors
3. Restart Home Assistant
4. Check Developer Tools → States for your sensors
5. Verify history graphs are working









