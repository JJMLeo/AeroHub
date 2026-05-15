// 气体特性计算工具模块
// 提供空气热力学属性计算、标准大气模型、单位转换等功能

// 标准大气返回数据接口
export interface AtmResult {
  Ts: number;  // 温度 (K)
  Ps: number;  // 压力 (Pa)
  rho: number; // 密度 (kg/m³)
}

// 空气热力学属性接口
export interface AirProps {
  MW:number;  // 空气摩尔质量 kg/mol
  cp: number;   // 定压比热容 [J/(kg·K)]
  cv: number;   // 定容比热容 [J/(kg·K)]
  gamma: number; // 比热比
  R: number;  // 空气气体常数 J/(kg·K)
  h: number;    // 比焓 [J/kg]
  s_psi: number;   // 熵函数 [J/(kg·K)]
}

// 单条结果结构（用于UI显示）
export interface ResultItem {
  label: string;
  value: string;
  unit: string;
}

// 历史记录结构
export interface HistoryItem {
  resultSummary: string;
  isISA: boolean;
}

export class GasProperties {
  // 通用常数
  static readonly Runiv: number = 8.314462618;      // 通用气体常数 J/(mol·K)

  // 系数多项式 (空气)
  static readonly polyA: number[] = [
    0.992313, 0.236688, -1.852148, 6.083152,  -8.893933, 7.097112,
    -3.234725, 0.794571, -0.081873, 0.422178, 0.001053
  ];

  // 系数多项式 (燃气)
  static readonly polyB: number[] = [
    -0.718874, 8.747481, -15.863157, 17.254096, -10.233795,
    3.081778, -0.361112, -0.003919, 0.055593, -0.0016079
  ];

  // 格式化数字，移除末尾的零
  static formatNumber(num: number, maxDec: number): string {
    let s = num.toFixed(maxDec);
    if (s.indexOf('.') !== -1) {
      s = s.replace(/\.?0+$/, '');
    }
    return s || '0';
  }

  // 多项式热力学属性计算 (空气)
  static getProps(T: number, FAR: number, Runiv: number = GasProperties.Runiv): AirProps {
    const MW_g_per_mol = 28.9647 - 0.946186 * FAR;        // 空气摩尔质量 g/mol (更精确值)
    const MW = MW_g_per_mol / 1000;                     // 转换为 kg/mol
    const R = Runiv / MW; // 空气气体常数 J/(kg·K)

    const f = Math.max(0, Math.min(FAR, 0.02)); // 0-2% 油气比范围

    // 限制温度范围，防止外插
    if (T < 200) T = 200;
    if (T > 2000) T = 2000;

    const a = GasProperties.polyA;
    const b = GasProperties.polyB;
    const T1 = T / 1000;
    const T2 = T1 * T1;
    const T3 = T2 * T1;
    const T4 = T3 * T1;
    const T5 = T4 * T1;
    const T6 = T5 * T1;
    const T7 = T6 * T1;
    const T8 = T7 * T1;
    const T9 = T8 * T1;

    // Cp [kJ/(kg·K)] -> 转换为 [J/(kg·K)]
    const cpa_kJ = a[0] + a[1] * T1 + a[2] * T2 + a[3] * T3 + a[4] * T4 + a[5] * T5 + a[6] * T6 + a[7] * T7 + a[8] * T8;
    const cpa = cpa_kJ * 1000; // 转换为 J/(kg·K)
    const cpg_kJ = b[0] + b[1] * T1 + b[2] * T2 + b[3] * T3 + b[4] * T4 + b[5] * T5 + b[6] * T6 + b[7] * T7;
    const cpg = cpg_kJ * 1000; // 转换为 J/(kg·K)
    const cp = cpa + f/(1+f) * cpg

    // 比热比 γ = cp / (cp - R)
    const gamma = cp / (cp - R);

    // 定容比热容 γ = cp / cv
    const cv = cp / gamma;

    // H [MJ/kg] -> 转换为 [J/kg]
    const ha_MJ = a[0] * T1 + a[1]/2 * T2 + a[2]/3 * T3 + a[3]/4 * T4 + a[4]/5 * T5 + a[5]/6 * T6 + a[6]/7 * T7 + a[7]/8 * T8
      + a[8]/9 * T9 + a[9];
    const hg_MJ = b[0] * T1 + b[1]/2 * T2 + b[2]/3 * T3 + b[3]/4 * T4 + b[4]/5 * T5 + b[5]/6 * T6 + b[6]/7 * T7 + b[8];

    // 混合气体 H [MJ/kg] -> 转换为 [J/kg]
    const h_MJ = ha_MJ + f/(1+f) * hg_MJ;
    const h = h_MJ * 1e6; // 转换为 J/kg

    // S [kJ/(kg·K)] -> 转换为 [J/(kg·K)]
    const sa_inc_kJ = a[0] * Math.log(T) + a[1] * T1 + a[2]/2 * T2 + a[3]/3 * T3 + a[4]/4 * T4 + a[5]/5 * T5
      + a[6]/6 * T6 + a[7]/7 * T7 + a[8]/8 * T8 + a[10];
    const sg_inc_kJ = b[0] * Math.log(T) + b[1] * T1 + b[2]/2 * T2 + b[3]/3 * T3 + b[4]/4 * T4 + b[5]/5 * T5
      + b[6]/6 * T6 + b[7]/7 * T7 + b[9];
    const s_inc_kJ = sa_inc_kJ + f / ( 1 + f ) * sg_inc_kJ
    const s_inc = s_inc_kJ * 1000; // 转换为 J/(kg·K)
    const s_psi = s_inc / R;

    return { MW, cp, cv, gamma, R, h, s_psi } as AirProps;
  }


  // 标准大气模型 (高度单位: km)
  static standardAtmosphere(H: number): AtmResult {
    let Ts: number, Ps: number;
    if (H <= 11) {
      Ts = 288.15 - 6.5 * H;
      Ps = 101325 * Math.pow(1 - H / 44.308, 5.25588);
    } else if (H <= 24.994) {
      Ts = 216.65;
      Ps = 22632.53 * Math.exp((11 - H) / 6.338);
    } else {
      Ts = 216.65 + 0.0029892 * (H - 24.994);
      Ps = 2523.7 * Math.pow((216.65 / Ts), 11.8);
    }
    const props = GasProperties.getProps(Ts, 0);
    return { Ts, Ps, rho: Ps / (props.R * Ts) };
  }

  // 温度单位转换到K (绝对温度)
  static toKelvinAbsolute(value: number, unit: string): number {
    switch (unit) {
      case 'K':  return value;
      case '°C': return value + 273.15;
      case '°F': return (value - 32) * 5 / 9 + 273.15;
      case '°R': return value * 5 / 9;
      default:   return value;
    }
  }

  // 温度单位转换到K (温差)
  static toKelvinDelta(value: number, unit: string): number {
    switch (unit) {
      case 'K':
      case '°C': return value;
      case '°F': return value * 5 / 9;
      case '°R': return value * 5 / 9;
      default:   return value;
    }
  }

  // 压力单位转换到Pa
  static toPascal(value: number, unit: string): number {
    switch (unit) {
      case 'Pa': return value;
      case 'kPa': return value * 1000;
      case 'atm': return value * 101325;
      case 'psi': return value * 6894.76;
      default: return value;
    }
  }

  // 温度单位转换到K (通用方法，兼容ThermodynamicProperties)
  static toKelvin(value: number, unit: string): number {
    return GasProperties.toKelvinAbsolute(value, unit);
  }

  // 声速计算 (m/s)
  static speedOfSound(gamma: number, R: number, T: number): number {
    return Math.sqrt(gamma * R * T);
  }

  // 密度计算 (kg/m³)
  static density(P: number, R: number, T: number): number {
    return P / (R * T);
  }

  // 计算等熵关系中的括号项 (1 + (γ-1)/2 * Ma²)
  static bracket(gamma: number, Ma: number): number {
    return 1 + (gamma - 1) / 2 * Ma * Ma;
  }

  // 总温 (绝热滞止温度) (K)
  static totalTemperature(Ts: number, gamma: number, Ma: number): number {
    return Ts * GasProperties.bracket(gamma, Ma);
  }

  // 总压 (等熵滞止压力) (Pa)
  static totalPressure(Ps: number, gamma: number, Ma: number): number {
    const bracket = GasProperties.bracket(gamma, Ma);
    return Ps * Math.pow(bracket, gamma / (gamma - 1));
  }

  // 总密度 (等熵滞止密度) (kg/m³)
  static totalDensity(rho: number, gamma: number, Ma: number): number {
    const bracket = GasProperties.bracket(gamma, Ma);
    return rho * Math.pow(bracket, 1 / (gamma - 1));
  }

  // 动压 (可压缩流修正) (Pa)
  static dynamicPressure(rho: number, c: number, gamma: number, Ma: number): number {
    if (Math.abs(Ma) < 1e-6) {
      // 马赫数接近0，使用不可压缩流公式
      return 0.5 * rho * c * c;
    } else {
      // 可压缩流修正公式
      const bracket = GasProperties.bracket(gamma, Ma);
      return 0.5 * rho * c * c *
        Math.pow(bracket, gamma / (gamma - 1) - 1) * 2 /
        (Ma * Ma * gamma);
    }
  }

  // 马赫角 (度)，仅当 Ma > 1 时有效，否则返回 NaN
  static machAngle(Ma: number): number {
    return Ma > 1 ? (Math.asin(1 / Ma) * 180 / Math.PI) : NaN;
  }

  // 速度系数 λ (无量纲)
  static velocityCoefficient(gamma: number, Ma: number): number {
    return Math.sqrt(((gamma + 1) * Ma * Ma) / (2 + (gamma - 1) * Ma * Ma));
  }

  // 根据速度和声速计算马赫数
  static machFromSpeed(c: number, a: number): number {
    return c / a;
  }

  // 根据马赫数和声速计算速度 (m/s)
  static speedFromMach(Ma: number, a: number): number {
    return Ma * a;
  }

  // 根据压力计算海拔高度 (km)，输入压力单位为Pa
  static pressureToAltitude(P: number): number {
    let H: number;
    // 海平面压力
    const P0 = 101325; // Pa
    // 11km处压力
    const P11 = 22632.53; // Pa
    // 24.994km处压力
    const P25 = 2523.7; // Pa
    
    if (P >= P11) {
      // 对流层 (0-11 km): P = P0 * (1 - H/44.308)^5.25588
      H = 44.33048 * (1 - Math.pow(P / P0, 0.1902632));
    } else if (P >= P25) {
      // 平流层下层 (11-24.994 km): P = P11 * exp((11 - H)/6.338)
      H = 11 - 6.338 * Math.log(P / P11);
    } else {
      // 平流层上层 (>24.994 km): P = P25 * (216.65/T)^11.8, T = 216.65 + 0.0029892*(H-24.994)
      // 需要数值求解，使用迭代法
      const T = 216.65 / Math.pow(P / P25, 1 / 11.8);
      H = 24.994 + (T - 216.65) / 0.0029892;
    }
    
    // 确保高度非负
    return Math.max(0, H);
  }
}