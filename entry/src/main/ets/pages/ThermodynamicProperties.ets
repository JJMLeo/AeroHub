// 物性参数计算页面
import router from '@ohos.router';
import { GasProperties, ResultItem, HistoryItem } from '../utils/GasProperties';
import { HistoryManager } from '../utils/HistoryManager';

@Entry
@Component
struct ThermodynamicProperties {
  @State fuelAirRatio: string = '0.02';      // 油气比 (默认2%)
  @State waterAirRatio: string = '0.0';      // 水气比 (kg water/kg dry air)
  @State temperature: string = '288.15';     // 静温 (K)
  @State pressure: string = '101.325';       // 静压 (kPa)
  @State tempUnit: string = 'K';             // 温度单位
  @State pressureUnit: string = 'kPa';       // 压力单位
  
  @State results: ResultItem[] = [];
  @State refreshFlag: number = 0;
  @State history: HistoryItem[] = [];
  // 防止单位切换时触发onFocus清空
  private preventFocusClear: boolean = false;

  // 通用常数
  private readonly R_universal: number = 8.314462618;      // 通用气体常数 (J/(mol·K))
  private readonly R_air: number = 287.058;                // 空气气体常数 (J/(kg·K))
  private readonly M_air: number = 0.0289647;              // 空气摩尔质量 (kg/mol)
  private readonly cp_air: number = 1005;                  // 空气定压比热容 (J/(kg·K))
  private readonly cv_air: number = 718;                   // 空气定容比热容 (J/(kg·K))
  private readonly gamma_air: number = 1.402;              // 空气比热比
  
  // 燃料属性 (假设为 Jet-A 航空煤油)
  private readonly M_fuel: number = 0.170;                 // 燃料摩尔质量 (kg/mol)
  private readonly cp_fuel: number = 2010;                 // 燃料定压比热容 (J/(kg·K))
  private readonly cv_fuel: number = 1720;                 // 燃料定容比热容 (J/(kg·K))
  private readonly gamma_fuel: number = 1.168;             // 燃料比热比
  private readonly h0_fuel: number = -4.28e7;              // 燃料标准生成焓 (J/kg)
  private readonly s0_fuel: number = 200;                  // 燃料标准熵 (J/(kg·K))
  
  // 水属性
  private readonly M_water: number = 0.01801528;           // 水摩尔质量 (kg/mol)
  private readonly cp_water: number = 4186;                // 水定压比热容 (J/(kg·K))
  private readonly R_water: number = 461.5;                // 水蒸气气体常数 (J/(kg·K))
  
  // 燃料热值 (Jet-A)
  private readonly fuelHeatingValue: number = 43.15e6;     // 燃料热值 (J/kg)
  
  // 安托万方程常数 (水蒸气饱和压力，温度范围 0-100°C)
  private readonly antoineA: number = 8.07131;
  private readonly antoineB: number = 1730.63;
  private readonly antoineC: number = 233.426;
  
  // 页面加载时获取历史记录
  aboutToAppear(): void {
    this.history = HistoryManager.getInstance().getHistory('ThermodynamicProperties');
  }

  build() {
    Column() {
      // ========== 标题 ==========
      Row() {
        Text('物性参数计算')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.primary_text'))
          .layoutWeight(1)
          .textAlign(TextAlign.Start)
        
        Button('←')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .width(48)
          .height(48)
          .fontColor($r('app.color.primary_text'))
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            router.back();
          })
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 8, bottom: 8 })
      .backgroundColor($r('app.color.primary_bg'))
      .alignItems(VerticalAlign.Center)

      // ========== 输入区 ==========
      Column() {
        // 1. 油气比输入
        Row() {
          Text('油气比:')
            .fontSize(14)
            .fontColor($r('app.color.primary_text'))
            .width(80)
          
          TextInput({ text: this.fuelAirRatio })
            .layoutWeight(1)
            .fontSize(16)
            .height(36)
            .textAlign(TextAlign.End)
            .backgroundColor($r('app.color.input_bg'))
            .border({ width: 2, color: $r('app.color.accent') })
            .fontColor($r('app.color.primary_text'))
            .borderRadius(8)
            .padding({ left: 12, right: 12 })
            .constraintSize({ minWidth: 120 })
            .onClick(() => {
              if (this.preventFocusClear) {
                this.preventFocusClear = false;
                return;
              }
              this.fuelAirRatio = '';
            })
            .onFocus(() => {
              if (this.preventFocusClear) {
                this.preventFocusClear = false;
                return;
              }
              this.fuelAirRatio = '';
            })
            .onChange((value: string) => { this.fuelAirRatio = value; })
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .layoutWeight(1)

        // 2. 水气比输入
        Row() {
          Text('水气比:')
            .fontSize(14)
            .fontColor($r('app.color.primary_text'))
            .width(80)
          
          TextInput({ text: this.waterAirRatio })
            .layoutWeight(1)
            .fontSize(16)
            .height(36)
            .textAlign(TextAlign.End)
            .backgroundColor($r('app.color.input_bg'))
            .border({ width: 2, color: $r('app.color.accent') })
            .fontColor($r('app.color.primary_text'))
            .borderRadius(8)
            .padding({ left: 12, right: 12 })
            .constraintSize({ minWidth: 120 })
            .onClick(() => {
              if (this.preventFocusClear) {
                this.preventFocusClear = false;
                return;
              }
              this.waterAirRatio = '';
            })
            .onFocus(() => {
              if (this.preventFocusClear) {
                this.preventFocusClear = false;
                return;
              }
              this.waterAirRatio = '';
            })
            .onChange((value: string) => { this.waterAirRatio = value; })
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .layoutWeight(1)

        // 3. 温度输入
        Row() {
          Text('静温:')
            .fontSize(14)
            .fontColor($r('app.color.primary_text'))
            .width(80)
          
          Row() {
            Select([{ value: 'K' }, { value: '°C' }, { value: '°F' }])
              .value(this.tempUnit)
              .font({ size: 14 })
              .fontColor($r('app.color.primary_text'))
              .selectedOptionFontColor($r('app.color.primary_text'))
              .selectedOptionBgColor($r('app.color.input_bg'))
              .optionFontColor($r('app.color.primary_text'))

              .height(36)
              .borderRadius(4)
              .shadow({ radius: 0 })
              .backgroundColor($r('app.color.input_bg'))
              .flexShrink(0)
              .constraintSize({ minWidth: 80 })
              .onSelect((index: number, value: string) => {
                this.preventFocusClear = true;
                this.tempUnit = value;
              })
          }
          .width(100)

          TextInput({ text: this.temperature })
            .layoutWeight(1)
            .fontSize(16)
            .height(36)
            .textAlign(TextAlign.End)
            .margin({ left: 12 })
            .backgroundColor($r('app.color.input_bg'))
            .border({ width: 2, color: $r('app.color.accent') })
            .fontColor($r('app.color.primary_text'))
            .borderRadius(8)
            .padding({ left: 12, right: 12 })
            .constraintSize({ minWidth: 120 })
            .onClick(() => {
              if (this.preventFocusClear) {
                this.preventFocusClear = false;
                return;
              }
              this.temperature = '';
            })
            .onFocus(() => {
              if (this.preventFocusClear) {
                this.preventFocusClear = false;
                return;
              }
              this.temperature = '';
            })
            .onChange((value: string) => { this.temperature = value; })
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .layoutWeight(1)

        // 4. 压力输入
        Row() {
          Text('静压:')
            .fontSize(14)
            .fontColor($r('app.color.primary_text'))
            .width(80)
          
          Row() {
            Select([{ value: 'kPa' }, { value: 'Pa' }, { value: 'atm' }, { value: 'psi' }])
              .value(this.pressureUnit)
              .font({ size: 14 })
              .fontColor($r('app.color.primary_text'))
              .selectedOptionFontColor($r('app.color.primary_text'))
              .selectedOptionBgColor($r('app.color.input_bg'))
              .optionFontColor($r('app.color.primary_text'))

              .height(36)
              .borderRadius(4)
              .shadow({ radius: 0 })
              .backgroundColor($r('app.color.input_bg'))
              .flexShrink(0)
              .constraintSize({ minWidth: 80 })
              .onSelect((index: number, value: string) => {
                this.preventFocusClear = true;
                this.pressureUnit = value;
              })
          }
          .width(100)

          TextInput({ text: this.pressure })
            .layoutWeight(1)
            .fontSize(16)
            .height(36)
            .textAlign(TextAlign.End)
            .margin({ left: 12 })
            .backgroundColor($r('app.color.input_bg'))
            .border({ width: 2, color: $r('app.color.accent') })
            .fontColor($r('app.color.primary_text'))
            .borderRadius(8)
            .padding({ left: 12, right: 12 })
            .constraintSize({ minWidth: 120 })
            .onClick(() => {
              if (this.preventFocusClear) {
                this.preventFocusClear = false;
                return;
              }
              this.pressure = '';
            })
            .onFocus(() => {
              if (this.preventFocusClear) {
                this.preventFocusClear = false;
                return;
              }
              this.pressure = '';
            })
            .onChange((value: string) => { this.pressure = value; })
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .layoutWeight(1)

        Button('计算')
          .width('100%')
          .height(40)
          .margin({ top: 8, bottom: 4 })
          .layoutWeight(1.2)
          .onClick(() => { this.calculate(); })
      }
      .padding({ left: 16, right: 16, top: 4, bottom: 4 })
      .backgroundColor($r('app.color.card_bg'))
      .layoutWeight(2)

      // ========== 输出区 ==========
      Column() {
        Divider().strokeWidth(2).color($r('app.color.divider'))
        
        Scroll() {
          Column() {
            ForEach(this.results,
              (item: ResultItem, index: number) => { this.resultRow(item) },
              (item: ResultItem, index: number) => `${index}-${item.label}-${this.refreshFlag}`
            )
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 4, bottom: 4 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      }
      .backgroundColor($r('app.color.card_bg'))
      .layoutWeight(3)

      // ========== 历史记录区 ==========
      Column() {
        Divider().strokeWidth(2).color($r('app.color.divider'))
        Text('计算历史')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .padding({ left: 16, top: 6, bottom: 4 })
          .backgroundColor($r('app.color.card_bg'))

        if (this.history.length === 0) {
          Text('暂无记录')
            .fontSize(12)
            .fontColor($r('app.color.hint_text'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding(12)
            .backgroundColor($r('app.color.card_bg'))
        }

        Scroll() {
          Column() {
            ForEach(this.history, (item: HistoryItem, index: number) => {
              Row() {
                Text(`${this.history.length - index}.`)
                  .fontSize(12)
                  .fontColor($r('app.color.primary_text'))
                  .width(24)

                Text(item.resultSummary)
                  .fontSize(12)
                  .fontColor($r('app.color.primary_text'))
                  .fontFamily('monospace') // 使用等宽字体以支持Tab对齐
                  .layoutWeight(1)

                if (item.isISA) {
                  Text('标准')
                    .fontSize(11)
                    .fontColor($r('app.color.hint_text'))
                    .width(30)
                }
              }
              .width('100%')
              .padding({ left: 16, right: 16, top: 6, bottom: 6 })
              Divider().color($r('app.color.divider')).strokeWidth(0.5)
            }, (item: HistoryItem, index: number) => `${index}-${item.resultSummary}-${item.isISA}`)
          }
          .width('100%')
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .constraintSize({ maxHeight: 120 }) // 限制最大高度，显示约4行历史记录
      }
      .layoutWeight(1) // 减少权重，让输入和输出区有更多空间
      .backgroundColor($r('app.color.card_bg'))
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  resultRow(item: ResultItem) {
    Column() {
      Row() {
        Text(item.label)
          .fontSize(13)
          .fontColor($r('app.color.primary_text'))
          .width(120)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Blank()
        Text(item.value)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.accent'))
          .textAlign(TextAlign.End)
          .maxLines(1)
        Text(item.unit)
          .fontSize(13)
          .fontColor($r('app.color.secondary_text'))
          .width(80)
          .padding({ left: 4 })
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
      Divider().color($r('app.color.divider')).strokeWidth(0.5)
    }
    .width('100%')
  }

  private calculate(): void {
    const f = parseFloat(this.fuelAirRatio);
    const w = parseFloat(this.waterAirRatio);
    const T_input = parseFloat(this.temperature);
    const P_input = parseFloat(this.pressure);
    
    if (isNaN(f) || isNaN(w) || isNaN(T_input) || isNaN(P_input)) return;
    
    // 单位转换
    const T = GasProperties.toKelvin(T_input, this.tempUnit);
    const P = GasProperties.toPascal(P_input, this.pressureUnit);
    
    // 油气比验证 (0-0.1 合理范围)
    const fuelAirRatio = Math.max(0, Math.min(f, 0.1));
    // 水气比验证 (0-0.1 合理范围)
    const waterAirRatio = Math.max(0, Math.min(w, 0.1));
    
    // 计算混合气体属性
    // 质量分数 (基于干空气质量=1)
    const m_air = 1;                    // 干空气质量 = 1
    const m_fuel = fuelAirRatio;        // 燃料质量 = 油气比
    const m_water = waterAirRatio;      // 水质量 = 水气比
    const m_total = m_air + m_fuel + m_water;
    
    // 摩尔分数
    const n_air = m_air / this.M_air;
    const n_fuel = m_fuel / this.M_fuel;
    const n_water = m_water / this.M_water;
    const n_total = n_air + n_fuel + n_water;
    
    const x_air = n_air / n_total;      // 空气摩尔分数
    const x_fuel = n_fuel / n_total;    // 燃料摩尔分数
    const x_water = n_water / n_total;  // 水蒸气摩尔分数
    
    // 平均分子量
    const M_mix = m_total / n_total;
    
    // 气体常数
    const R_mix = this.R_universal / M_mix;
    
    // 比热容 (质量加权平均)
    const cp_mix = (m_air * this.cp_air + m_fuel * this.cp_fuel + m_water * this.cp_water) / m_total;
    const cv_mix = cp_mix - R_mix;  // 从cp和R计算cv
    
    // 比热比
    const gamma_mix = cp_mix / cv_mix;
    
    // 焓 (参考温度 298.15K)
    const T_ref = 298.15;
    const h_air = this.cp_air * (T - T_ref);
    const h_fuel = this.cp_fuel * (T - T_ref) + this.h0_fuel;
    const h_water = this.cp_water * (T - T_ref) + 2.5e6; // 包含汽化潜热近似值
    let h_mix = (m_air * h_air + m_fuel * h_fuel + m_water * h_water) / m_total;
    // 确保焓不为负
    if (h_mix < 0) h_mix = 0;
    
    // 熵 (参考压力 101325 Pa)
    const P_ref = 101325;
    const s_air = this.cp_air * Math.log(T / T_ref) - this.R_air * Math.log(P / P_ref);
    const s_fuel = this.cp_fuel * Math.log(T / T_ref) - this.R_universal / this.M_fuel * Math.log(P / P_ref) + this.s0_fuel;
    const s_water = this.cp_water * Math.log(T / T_ref) - this.R_water * Math.log(P / P_ref);
    let s_mix = (m_air * s_air + m_fuel * s_fuel + m_water * s_water) / m_total;
    // 确保熵不为负
    if (s_mix < 0) s_mix = 0;
    
    // 密度
    const rho_mix = GasProperties.density(P, R_mix, T);
    
    // 声速
    const a = GasProperties.speedOfSound(gamma_mix, R_mix, T);
    
    // 计算雷诺数指数 (基于动力黏度)
    // 使用萨瑟兰公式计算空气动力黏度 (μ, Pa·s)
    const mu0 = 1.716e-5;  // 参考黏度 at 273.15K (Pa·s)
    const T0 = 273.15;     // 参考温度 (K)
    const S = 110.4;       // 萨瑟兰常数 (K)
    const mu_air = mu0 * Math.pow(T / T0, 1.5) * (T0 + S) / (T + S);
    
    // 雷诺数指数 (Re指数，无量纲)
    const reynoldsIndex = rho_mix * a / mu_air;  // 基于声速的特征速度

    // 计算其他输运属性
    const nu_air = mu_air / rho_mix;  // 运动粘度 (m²/s)
    // 热导率 (W/(m·K))，使用空气的近似公式
    const k_air = 0.02624 * Math.pow(T / 300, 0.8);
    const prandtlNumber = cp_mix * mu_air / k_air;  // 普朗特数
    // 计算相对湿度
    // 安托万方程计算饱和水蒸气压力 (mmHg)
    const T_C = T - 273.15;
    let p_sat_mmHg = 0;
    if (T_C >= 0 && T_C <= 100) {
      p_sat_mmHg = Math.pow(10, this.antoineA - this.antoineB / (T_C + this.antoineC));
    } else if (T_C < 0) {
      // 低于0°C使用冰面公式近似
      p_sat_mmHg = Math.pow(10, 9.5 - 2667 / T);
    } else {
      // 高于100°C使用克劳修斯-克拉佩龙方程近似
      p_sat_mmHg = 760 * Math.exp(20.386 - 5132 / T);
    }
    
    // 转换为Pa
    const p_sat_Pa = p_sat_mmHg * 133.322;
    
    // 水蒸气分压 (基于水气比)
    const p_water = x_water * P;
    
    // 相对湿度
    const relativeHumidity = p_sat_Pa > 0 ? Math.min(p_water / p_sat_Pa * 100, 100) : 0;
    
    // 计算压力高度
    const pressureAltitude = GasProperties.pressureToAltitude(P);
    
    // 生成结果
    const results: ResultItem[] = [
      { label: '静压', value: GasProperties.formatNumber(P / 1000, 3), unit: 'kPa' },
      { label: '静温', value: GasProperties.formatNumber(T, 2), unit: 'K' },
      { label: '密度', value: GasProperties.formatNumber(rho_mix, 4), unit: 'kg/m³' },
      { label: '声速', value: GasProperties.formatNumber(a, 2), unit: 'm/s' },
      { label: '空气摩尔质量', value: GasProperties.formatNumber(M_mix * 1000, 3), unit: 'g/mol' },
      { label: '气体常数', value: GasProperties.formatNumber(R_mix, 3), unit: 'J/(kg·K)' },
      { label: '定压比热容', value: GasProperties.formatNumber(cp_mix, 2), unit: 'J/(kg·K)' },
      { label: '定容比热容', value: GasProperties.formatNumber(cv_mix, 2), unit: 'J/(kg·K)' },
      { label: '比热比', value: GasProperties.formatNumber(gamma_mix, 4), unit: '' },
      { label: '动力粘度', value: GasProperties.formatNumber(mu_air, 6), unit: 'Pa·s' },
      { label: '运动粘度', value: GasProperties.formatNumber(nu_air, 8), unit: 'm²/s' },
      { label: '热导率', value: GasProperties.formatNumber(k_air, 5), unit: 'W/(m·K)' },
      { label: '普朗特数', value: GasProperties.formatNumber(prandtlNumber, 4), unit: '' },
      { label: '雷诺数指数', value: GasProperties.formatNumber(reynoldsIndex, 3), unit: '' },
      { label: '相对湿度', value: GasProperties.formatNumber(relativeHumidity, 1), unit: '%' },
      { label: '焓', value: GasProperties.formatNumber(h_mix / 1000, 3), unit: 'kJ/kg' },
      { label: '熵', value: GasProperties.formatNumber(s_mix, 3), unit: 'J/(kg·K)' },
      { label: '空气摩尔分数', value: GasProperties.formatNumber(x_air * 100, 2), unit: '%' },
      { label: '燃料摩尔分数', value: GasProperties.formatNumber(x_fuel * 100, 4), unit: '%' },
      { label: '水蒸气摩尔分数', value: GasProperties.formatNumber(x_water * 100, 4), unit: '%' },
      { label: '压力高度', value: GasProperties.formatNumber(pressureAltitude, 2), unit: 'km' }
    ];
    
    this.results = results;
    this.refreshFlag++;
    
    // 添加到历史记录
    const currentSnapshot = `${fuelAirRatio}|${waterAirRatio}|${T}|${P}`;
    const newEntry: HistoryItem = {
      resultSummary: `f=${GasProperties.formatNumber(fuelAirRatio * 100, 2)}%\tw=${GasProperties.formatNumber(waterAirRatio * 100, 2)}%\tT=${GasProperties.formatNumber(T - 273.15, 1)}°C\tP=${GasProperties.formatNumber(P / 1000, 1)}kPa`,
      isISA: Math.abs(T - 288.15) < 1 && Math.abs(P - 101325) < 100
    };
    HistoryManager.getInstance().addHistory('ThermodynamicProperties', newEntry, currentSnapshot);
    this.history = HistoryManager.getInstance().getHistory('ThermodynamicProperties');
  }
}

