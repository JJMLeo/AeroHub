// HB5652.1标准温度曲线数据
// 高温天：1%概率极值，低温天：20%概率极值

export interface TemperaturePoint {
  altitude: number;  // 高度 (km)
  tempHot: number;   // 高温天温度 (°C)
  tempStd: number;   // 标准天温度 (°C)
  tempCold: number;  // 低温天温度 (°C)
}

export interface CalculatedTemperatures {
  hot: number;   // 高温天温度 (°C)
  std: number;   // 标准天温度 (°C)
  cold: number;  // 低温天温度 (°C)
}

export interface TemperatureRange {
  min: number;
  max: number;
}

export class TemperatureCurveData {
  // HB5652.1标准数据：0-18km，每千米一个温度点
  private static readonly HOT_TEMP_DATA: number[] = [
    49, 40, 30, 23.5, 17, 11.5, 6, 0.5, -5, -9, -13, -17.5, -22, -26, -30, -33.5, -37, -37, -37
  ];
  
  private static readonly COLD_TEMP_DATA: number[] = [
    -51, -49, -31, -35.5, -40, -45.5, -51, -56, -61, -63, -65, -66, -67, -68.5, -70, -76, -82, -81, -82
  ];
  
  // 标准大气参数
  private static readonly T0: number = 288.15;  // 海平面温度 (K)
  private static readonly L: number = -0.0065;  // 温度递减率 (K/m)
  
  // 计算标准天温度（国际标准大气模型）
  private static getStandardTemperature(altitudeKm: number): number {
    const altitudeM = altitudeKm * 1000;
    let tempK: number;
    
    if (altitudeM <= 11000) {
      // 对流层：0-11km
      tempK = TemperatureCurveData.T0 + TemperatureCurveData.L * altitudeM;
    } else {
      // 平流层下层：11-20km（等温层）
      tempK = 216.65;
    }
    
    // 转换为摄氏度
    return tempK - 273.15;
  }
  
  // 获取完整的温度曲线数据（0-18km）
  public static getCurveData(): TemperaturePoint[] {
    const data: TemperaturePoint[] = [];
    
    for (let i = 0; i <= 18; i++) {
      const point: TemperaturePoint = {
        altitude: i,
        tempHot: TemperatureCurveData.HOT_TEMP_DATA[i],
        tempStd: TemperatureCurveData.getStandardTemperature(i),
        tempCold: TemperatureCurveData.COLD_TEMP_DATA[i]
      };
      data.push(point);
    }
    
    return data;
  }
  
  // 根据高度插值计算三个温度值
  public static getTemperaturesAtAltitude(altitudeKm: number): CalculatedTemperatures {
    // 限制在0-18km范围内
    const h = Math.max(0, Math.min(18, altitudeKm));
    
    // 找到插值区间
    const lowerIdx = Math.floor(h);
    const upperIdx = Math.min(lowerIdx + 1, 18);
    const ratio = h - lowerIdx;
    
    // 线性插值
    const hot = TemperatureCurveData.HOT_TEMP_DATA[lowerIdx] + 
                (TemperatureCurveData.HOT_TEMP_DATA[upperIdx] - TemperatureCurveData.HOT_TEMP_DATA[lowerIdx]) * ratio;
    const cold = TemperatureCurveData.COLD_TEMP_DATA[lowerIdx] + 
                 (TemperatureCurveData.COLD_TEMP_DATA[upperIdx] - TemperatureCurveData.COLD_TEMP_DATA[lowerIdx]) * ratio;
    const std = TemperatureCurveData.getStandardTemperature(h);
    
    const result: CalculatedTemperatures = { hot: hot, std: std, cold: cold };
    return result;
  }
  
  // 获取温度范围（用于绘图坐标轴）
  public static getTemperatureRange(): TemperatureRange {
    let min = Math.min(...TemperatureCurveData.COLD_TEMP_DATA);
    let max = Math.max(...TemperatureCurveData.HOT_TEMP_DATA);
    
    // 添加一些边距
    min = Math.floor(min / 10) * 10 - 10;
    max = Math.ceil(max / 10) * 10 + 10;
    
    const range: TemperatureRange = { min: min, max: max };
    return range;
  }
}
