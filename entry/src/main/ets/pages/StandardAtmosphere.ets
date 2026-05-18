// 标准大气计算页面
import router from '@ohos.router';
import { GasProperties, AtmResult, AirProps, ResultItem, HistoryItem } from '../utils/GasProperties';
import { HistoryManager } from '../utils/HistoryManager';
import { TemperatureCurveData, TemperaturePoint, CalculatedTemperatures, TemperatureRange } from '../utils/TemperatureCurveData';

// 绘图区域边距接口
interface ChartPadding {
  left: number;
  right: number;
  top: number;
  bottom: number;
}

@Entry
@Component
struct StandardAtmosphere {
  @State altitudeValue: string = '0';
  @State altitudeUnit: string = 'km';
  @State unitSystem: string = '国际单位';
  
  @State resultsSI: ResultItem[] = [];  // 国际单位结果
  @State resultsImperial: ResultItem[] = [];  // 英制单位结果
  @State refreshFlag: number = 0;
  @State history: HistoryItem[] = [];
  // 防止单位切换时触发onFocus清空
  private preventFocusClear: boolean = false;
  
  // 曲线图相关状态
  @State showChart: boolean = false;  // 是否显示曲线图
  @State axisSwapped: boolean = false;  // 是否交换横纵坐标轴
  @State calculatedAltitude: number = -1;  // 计算的高度值(km)，-1表示未计算
  @State calculatedTemps: CalculatedTemperatures | null = null;  // 计算高度的温度值
  private curveData: TemperaturePoint[] = TemperatureCurveData.getCurveData();  // 曲线数据

  // 物理常数（标准大气模型参数）
  private readonly g0: number = 9.80665;          // 重力加速度 (m/s²)
  private readonly T0: number = 288.15;           // 海平面温度 (K)
  private readonly P0: number = 101325;           // 海平面压力 (Pa)
  private readonly L: number = -0.0065;           // 温度递减率 (K/m)
  // 其他常数（如气体常数、摩尔质量等）从GasProperties获取

  // 单位转换常数
  private readonly FT_TO_M: number = 0.3048;
  private readonly K_TO_F: number = 1.8;
  private readonly K_TO_R: number = 1.8;
  private readonly PA_TO_PSI: number = 0.000145038;
  private readonly PA_TO_INHG: number = 0.0002953;
  private readonly KG_M3_TO_SLUG_FT3: number = 0.00194032;
  // 热力学单位转换常数
  private readonly JKGK_TO_FTLBFLBR: number = 0.185863;      // J/(kg·K) 到 ft·lbf/(lb·°R)
  private readonly JKGK_TO_BTULBR: number = 0.000238846;    // J/(kg·K) 到 Btu/(lb·°R)
  
  // 页面加载时获取历史记录
  aboutToAppear(): void {
    this.history = HistoryManager.getInstance().getHistory('StandardAtmosphere');
  }

  build() {
    Column() {
      // ========== 标题 ==========
      Row() {
        Text('标准大气计算')
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
        // 1. 高度行
        Row() {
          Text('高度:')
            .fontSize(14)
            .fontColor($r('app.color.primary_text'))
            .width(80)
            .textAlign(TextAlign.End)

          Select([{ value: 'km' }, { value: 'ft' }])
            .value(this.altitudeUnit)
            .font({ size: 14 })
            .fontColor($r('app.color.primary_text'))
            .height(36)
            .borderRadius(4)
            .shadow({ radius: 0 })
            .backgroundColor($r('app.color.input_bg'))
            .layoutWeight(1)
            .margin({ left: 12 })
            .onSelect((index: number, value: string) => {
              this.preventFocusClear = true;
              this.altitudeUnit = value;
              // 切换单位后重绘曲线
              if (this.showChart) {
                this.drawTemperatureCurves();
              }
            })

          TextInput({ text: this.altitudeValue })
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
              this.altitudeValue = '';
            })
            .onFocus(() => {
              if (this.preventFocusClear) {
                this.preventFocusClear = false;
                return;
              }
              this.altitudeValue = '';
            })
            .onChange((value: string) => { this.altitudeValue = value; })
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .layoutWeight(1)

        // 2. 单位系统选择
        Row() {
          Text('单位系统:')
            .fontSize(14)
            .fontColor($r('app.color.primary_text'))
            .width(80)
            .textAlign(TextAlign.End)
          
          Select([{ value: '国际单位' }, { value: '英制单位' }])
            .value(this.unitSystem)
            .font({ size: 14 })
            .fontColor($r('app.color.primary_text'))
            .height(36)
            .borderRadius(4)
            .shadow({ radius: 0 })
            .backgroundColor($r('app.color.input_bg'))
            .layoutWeight(1)
            .margin({ left: 12 })
            .onSelect((index: number, value: string) => {
              this.preventFocusClear = true;
              this.unitSystem = value;
              this.refreshFlag++;
              // 切换单位后重绘曲线
              if (this.showChart) {
                this.drawTemperatureCurves();
              }
            })
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })
        .layoutWeight(1)

        Button('计算')
          .width('100%')
          .height(40)
          .margin({ top: 8, bottom: 4 })
          .layoutWeight(1)
          .onClick(() => { this.calculate(); })
      }
      .padding({ left: 16, right: 16, top: 4, bottom: 4 })
      .backgroundColor($r('app.color.card_bg'))
      .layoutWeight(1.5)

      // ========== 输出区（弹性高度）==========
      Column() {
        Divider().strokeWidth(2).color($r('app.color.divider'))

        if (this.showChart) {
          // 曲线图模式
          Stack({ alignContent: Alignment.TopEnd }) {
            // 曲线图Canvas
            Column() {
              Canvas(this.getChartContext())
                .width('100%')
                .height('100%')
                .onReady(() => {
                  this.drawTemperatureCurves();
                })
            }
            .width('100%')
            .layoutWeight(1)
            .padding({ left: 16, right: 16, top: 8, bottom: 8 })
            
            // 隐蔽的坐标轴切换按钮（右上角，半透明）
            Button(this.axisSwapped ? '纵轴:温度' : '纵轴:高度')
              .fontSize(10)
              .fontColor($r('app.color.hint_text'))
              .backgroundColor(Color.Transparent)
              .height(20)
              .padding({ left: 4, right: 4 })
              .margin({ top: 4, right: 4 })
              .opacity(0.5)
              .onClick(() => {
                this.axisSwapped = !this.axisSwapped;
                // 触发曲线重绘
                this.drawTemperatureCurves();
              })
          }
          .width('100%')
          .layoutWeight(1)
        } else {
          // 结果表格模式
          Scroll() {
            Column() {
              if (this.unitSystem === '国际单位') {
                ForEach(this.resultsSI,
                  (item: ResultItem, index: number) => { this.resultRow(item) },
                  (item: ResultItem, index: number) => `${index}-${item.label}-${item.unit}-${this.refreshFlag}`
                )
              } else {
                ForEach(this.resultsImperial,
                  (item: ResultItem, index: number) => { this.resultRow(item) },
                  (item: ResultItem, index: number) => `${index}-${item.label}-${item.unit}-${this.refreshFlag}`
                )
              }
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 8, bottom: 4 })
          }
          .layoutWeight(1)
          .scrollBar(BarState.Auto)
        }
      }
      .layoutWeight(4)
      .backgroundColor($r('app.color.card_bg'))
      .onClick(() => {
        // 点击空白处切换显示模式
        if (this.resultsSI.length > 0 || this.resultsImperial.length > 0) {
          this.showChart = !this.showChart;
        }
      })

      // ========== 历史记录区 ==========
      Column() {
        Divider().strokeWidth(2).color($r('app.color.divider'))
        Text('计算历史')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.primary_text'))
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
                  Text('标准大气')
                    .fontSize(11)
                    .fontColor($r('app.color.hint_text'))
                    .width(50)
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
      }
      .layoutWeight(1)
      .backgroundColor($r('app.color.card_bg'))
      .constraintSize({ maxHeight: 120 })
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
          .width(90)
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
          .width(160)
          .padding({ left: 4 })
          .maxLines(1)
          .textAlign(TextAlign.Start)
      }
      .width('100%')
      .padding({ top: 8, bottom: 8 })
      Divider().color($r('app.color.divider')).strokeWidth(0.5)
    }
    .width('100%')
  }

  private formatNumber(num: number, maxDec: number): string {
    let s = num.toFixed(maxDec);
    if (s.indexOf('.') !== -1) {
      s = s.replace(/\.?0+$/, '');
    }
    return s || '0';
  }

  // 转换到英制单位
  private convertToImperial(result: AtmResult): AtmResult {
    // 温度: K -> °F
    const Ts_F = (result.Ts - 273.15) * 9/5 + 32;
    // 压力: Pa -> psi 和 inHg
    const Ps_psi = result.Ps * this.PA_TO_PSI;
    // const Ps_inHg = result.Ps * this.PA_TO_INHG;
    // 密度: kg/m³ -> slug/ft³
    const rho_slug_ft3 = result.rho * this.KG_M3_TO_SLUG_FT3;
    
    return {
      Ts: Ts_F,
      Ps: Ps_psi,  // 返回 psi，但显示时会同时显示两种
      rho: rho_slug_ft3
    };
  }

  private calculate(): void {
    const altVal = parseFloat(this.altitudeValue);
    if (isNaN(altVal)) return;

    // 转换为米
    let altitudeM = altVal;
    if (this.altitudeUnit === 'ft') {
      altitudeM = altVal * this.FT_TO_M;
    } else {
      altitudeM = altVal * 1000;  // km to m
    }

    // 计算标准大气参数
    const resultSI = GasProperties.standardAtmosphere(altitudeM / 1000);
    const resultImperial = this.convertToImperial(resultSI);

    // 获取空气属性（用于计算声速等）
    const airProps = GasProperties.getProps(resultSI.Ts, 0);
    const speedOfSoundSI = GasProperties.speedOfSound(airProps.gamma, airProps.R, resultSI.Ts);
    
    // 英制单位热力学参数
    const MW_g_per_mol = airProps.MW * 1000; // g/mol (单位不变)
    const R_imperial = airProps.R * this.JKGK_TO_FTLBFLBR; // ft·lbf/(lb·°R)
    const cp_imperial = airProps.cp * this.JKGK_TO_BTULBR; // Btu/(lb·°R)
    const cv_imperial = airProps.cv * this.JKGK_TO_BTULBR; // Btu/(lb·°R)

    // 计算高度转换结果
    const altKm = altitudeM / 1000;
    const altFt = altKm * 3280.84;
    const convertedAltValue = this.altitudeUnit === 'km' ? 
      this.formatNumber(altFt, 0) : 
      this.formatNumber(altKm, 2);
    const convertedAltUnit = this.altitudeUnit === 'km' ? 'ft' : 'km';

    const resultsSI: ResultItem[] = [
      { label: '高度', value: convertedAltValue, unit: convertedAltUnit },
      { label: '静温', value: this.formatNumber(resultSI.Ts, 2), unit: 'K' },
      { label: '  ', value: this.formatNumber(resultSI.Ts - 273.15, 2), unit: '°C' },
      { label: '静压', value: this.formatNumber(resultSI.Ps / 1000, 3), unit: 'kPa' },
      { label: '  ', value: this.formatNumber(resultSI.Ps / 101325, 4), unit: 'atm' },
      { label: '密度', value: this.formatNumber(resultSI.rho, 4), unit: 'kg/m³' },
      { label: '声速', value: this.formatNumber(speedOfSoundSI, 2), unit: 'm/s' },
      { label: '空气摩尔质量', value: this.formatNumber(airProps.MW * 1000, 3), unit: 'g/mol' },
      { label: '气体常数', value: this.formatNumber(airProps.R, 4), unit: 'J/(kg·K)' },
      { label: '定压比热容', value: this.formatNumber(airProps.cp, 2), unit: 'J/(kg·K)' },
      { label: '定容比热容', value: this.formatNumber(airProps.cv, 2), unit: 'J/(kg·K)' },
      { label: '比热比', value: this.formatNumber(airProps.gamma, 5), unit: '' }
    ];

    // 英制单位结果（合并相同标签）
    const resultsImperial: ResultItem[] = [
      { label: '高度', value: convertedAltValue, unit: convertedAltUnit },
      { label: '静温', value: this.formatNumber(resultImperial.Ts, 2), unit: '°F' },
      { label: '  ', value: this.formatNumber(resultSI.Ts * 9 / 5, 2), unit: '°R' },
      { label: '静压', value: this.formatNumber(resultImperial.Ps, 4), unit: 'psi' },
      { label: '  ', value: this.formatNumber(resultSI.Ps * this.PA_TO_INHG, 3), unit: 'inHg' },
      { label: '密度', value: this.formatNumber(resultImperial.rho, 5), unit: 'slug/ft³' },
      { label: '声速', value: this.formatNumber(speedOfSoundSI * 3.28084, 2), unit: 'ft/s' },
      { label: '空气摩尔质量', value: this.formatNumber(MW_g_per_mol, 3), unit: 'g/mol' },
      { label: '气体常数', value: this.formatNumber(R_imperial, 5), unit: 'ft·lbf/(lb·°R)' },
      { label: '定压比热容', value: this.formatNumber(cp_imperial, 5), unit: 'Btu/(lb·°R)' },
      { label: '定容比热容', value: this.formatNumber(cv_imperial, 5), unit: 'Btu/(lb·°R)' },
      { label: '比热比', value: this.formatNumber(airProps.gamma, 5), unit: '' }
    ];
    this.resultsSI = resultsSI;
    this.resultsImperial = resultsImperial;
    this.refreshFlag++;

    // 添加到历史记录
    const currentSnapshot = `${altVal}|${this.altitudeUnit}|${this.unitSystem}`;
    const newEntry: HistoryItem = {
      resultSummary: `H=${this.formatNumber(altKm, 1)}km\tT=${this.formatNumber(resultSI.Ts - 273.15, 1)}°C\tP=${this.formatNumber(resultSI.Ps / 1000, 1)}kPa`,
      isISA: true
    };
    HistoryManager.getInstance().addHistory('StandardAtmosphere', newEntry, currentSnapshot);
    this.history = HistoryManager.getInstance().getHistory('StandardAtmosphere');
    
    // 保存计算高度和温度值（用于曲线图标记）
    this.calculatedAltitude = altKm;
    this.calculatedTemps = TemperatureCurveData.getTemperaturesAtAltitude(altKm);
    
    // 如果当前显示曲线图，则更新曲线
    if (this.showChart) {
      this.drawTemperatureCurves();
    }
  }
  
  // 获取Canvas绘图上下文
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  
  private getChartContext(): CanvasRenderingContext2D {
    return this.context;
  }
  
  // 绘制温度曲线
  private drawTemperatureCurves(): void {
    const ctx = this.context;
    const width = ctx.width;
    const height = ctx.height;
    
    // 绘图区域边距（根据字体大小调整，大幅增加）
    const padding: ChartPadding = { left: 70, right: 30, top: 30, bottom: 60 };
    const chartWidth = width - padding.left - padding.right;
    const chartHeight = height - padding.top - padding.bottom;
    
    // 清空画布
    ctx.clearRect(0, 0, width, height);
    
    // 获取温度范围
    const tempRange = TemperatureCurveData.getTemperatureRange();
    let minTemp = tempRange.min;
    let maxTemp = tempRange.max;
    
    // 如果是英制单位，将温度范围转换为华氏度
    if (this.unitSystem === '英制单位') {
      minTemp = minTemp * 9 / 5 + 32;
      maxTemp = maxTemp * 9 / 5 + 32;
    }
    
    const minAlt = 0;
    const maxAlt = 18;
    
    // 坐标转换函数
    const toX = this.axisSwapped ? 
      (temp: number) => padding.left + (temp - minTemp) / (maxTemp - minTemp) * chartWidth :
      (alt: number) => padding.left + alt / maxAlt * chartWidth;
    
    const toY = this.axisSwapped ?
      (alt: number) => padding.top + (maxAlt - alt) / maxAlt * chartHeight :
      (temp: number) => padding.top + (maxTemp - temp) / (maxTemp - minTemp) * chartHeight;
    
    // 绘制背景网格
    ctx.strokeStyle = '#E0E0E0';
    ctx.lineWidth = 0.5;
    
    // 绘制网格线
    for (let alt = 0; alt <= 18; alt += 3) {
      const x = this.axisSwapped ? toX(minTemp) : toX(alt);
      const y = this.axisSwapped ? toY(alt) : toY(minTemp);
      ctx.beginPath();
      if (this.axisSwapped) {
        ctx.moveTo(padding.left, y);
        ctx.lineTo(width - padding.right, y);
      } else {
        ctx.moveTo(x, padding.top);
        ctx.lineTo(x, height - padding.bottom);
      }
      ctx.stroke();
    }
    
    for (let temp = Math.ceil(minTemp / 20) * 20; temp <= maxTemp; temp += 20) {
      const x = this.axisSwapped ? toX(temp) : toX(maxAlt);
      const y = this.axisSwapped ? toY(maxAlt) : toY(temp);
      ctx.beginPath();
      if (this.axisSwapped) {
        ctx.moveTo(x, padding.top);
        ctx.lineTo(x, height - padding.bottom);
      } else {
        ctx.moveTo(padding.left, y);
        ctx.lineTo(width - padding.right, y);
      }
      ctx.stroke();
    }
    
    // 绘制四周加粗边框
    ctx.strokeStyle = '#333333';
    ctx.lineWidth = 2.5;
    // 左边框
    ctx.beginPath();
    ctx.moveTo(padding.left, padding.top);
    ctx.lineTo(padding.left, height - padding.bottom);
    ctx.stroke();
    // 右边框
    ctx.beginPath();
    ctx.moveTo(width - padding.right, padding.top);
    ctx.lineTo(width - padding.right, height - padding.bottom);
    ctx.stroke();
    // 上边框
    ctx.beginPath();
    ctx.moveTo(padding.left, padding.top);
    ctx.lineTo(width - padding.right, padding.top);
    ctx.stroke();
    // 下边框
    ctx.beginPath();
    ctx.moveTo(padding.left, height - padding.bottom);
    ctx.lineTo(width - padding.right, height - padding.bottom);
    ctx.stroke();
    
    // 绘制坐标轴标签（大幅增大字体，确保清晰可见）
    ctx.fillStyle = '#333333';
    ctx.font = '24px sans-serif';
    ctx.textAlign = 'center';
    
    // 获取当前单位
    const altitudeUnitLabel = this.altitudeUnit;
    const tempUnitLabel = this.unitSystem === '国际单位' ? '°C' : '°F';
    
    // X轴标签
    if (this.axisSwapped) {
      // X轴为温度
      for (let temp = Math.ceil(minTemp / 20) * 20; temp <= maxTemp; temp += 20) {
        const x = toX(temp);
        ctx.fillText(`${temp}`, x, height - padding.bottom + 30);
      }
      ctx.font = '28px sans-serif';
      ctx.fillText(`温度 (${tempUnitLabel})`, width / 2, height - 8);
    } else {
      // X轴为高度
      for (let alt = 0; alt <= 18; alt += 3) {
        const x = toX(alt);
        ctx.fillText(`${alt}`, x, height - padding.bottom + 30);
      }
      ctx.font = '28px sans-serif';
      ctx.fillText(`高度 (${altitudeUnitLabel})`, width / 2, height - 8);
    }
    
    // Y轴标签
    ctx.font = '24px sans-serif';
    ctx.textAlign = 'right';
    if (this.axisSwapped) {
      // Y轴为高度
      for (let alt = 0; alt <= 18; alt += 3) {
        const y = toY(alt);
        ctx.fillText(`${alt}`, padding.left - 15, y + 8);
      }
      ctx.save();
      ctx.translate(25, height / 2);
      ctx.rotate(-Math.PI / 2);
      ctx.textAlign = 'center';
      ctx.font = '28px sans-serif';
      ctx.fillText(`高度 (${altitudeUnitLabel})`, 0, 0);
      ctx.restore();
    } else {
      // Y轴为温度
      for (let temp = Math.ceil(minTemp / 20) * 20; temp <= maxTemp; temp += 20) {
        const y = toY(temp);
        ctx.fillText(`${temp}`, padding.left - 15, y + 8);
      }
      ctx.save();
      ctx.translate(25, height / 2);
      ctx.rotate(-Math.PI / 2);
      ctx.textAlign = 'center';
      ctx.font = '28px sans-serif';
      ctx.fillText(`温度 (${tempUnitLabel})`, 0, 0);
      ctx.restore();
    }
    
    // 绘制曲线函数
    const drawCurve = (data: number[], color: string, lineWidth: number) => {
      ctx.strokeStyle = color;
      ctx.lineWidth = lineWidth;
      ctx.beginPath();
      
      for (let i = 0; i < data.length; i++) {
        const alt = i;
        let temp = data[i];
        // 如果是英制单位，将摄氏度转换为华氏度
        if (this.unitSystem === '英制单位') {
          temp = temp * 9 / 5 + 32;
        }
        const x = this.axisSwapped ? toX(temp) : toX(alt);
        const y = this.axisSwapped ? toY(alt) : toY(temp);
        
        if (i === 0) {
          ctx.moveTo(x, y);
        } else {
          ctx.lineTo(x, y);
        }
      }
      ctx.stroke();
    };
    
    // 绘制三条曲线（修正颜色）
    // 高温天曲线（红色）
    const hotData = this.curveData.map(p => p.tempHot);
    drawCurve(hotData, '#FF4444', 2.5);
    
    // 标准天曲线（绿色）
    const stdData = this.curveData.map(p => p.tempStd);
    drawCurve(stdData, '#44BB44', 2.5);
    
    // 低温天曲线（蓝色）
    const coldData = this.curveData.map(p => p.tempCold);
    drawCurve(coldData, '#4444FF', 2.5);
    
    // 如果有计算高度，绘制标记点
    if (this.calculatedAltitude >= 0 && this.calculatedTemps) {
      const alt = this.calculatedAltitude;
      const temps = this.calculatedTemps;
      
      // 绘制三个标记点
      const drawMarker = (tempC: number, color: string, label: string) => {
        // 如果是英制单位，将摄氏度转换为华氏度
        let temp = tempC;
        if (this.unitSystem === '英制单位') {
          temp = tempC * 9 / 5 + 32;
        }
        
        const x = this.axisSwapped ? toX(temp) : toX(alt);
        const y = this.axisSwapped ? toY(alt) : toY(temp);
        
        // 绘制圆点
        ctx.fillStyle = color;
        ctx.beginPath();
        ctx.arc(x, y, 8, 0, 2 * Math.PI);
        ctx.fill();
        
        // 绘制白色内圈
        ctx.fillStyle = '#FFFFFF';
        ctx.beginPath();
        ctx.arc(x, y, 4, 0, 2 * Math.PI);
        ctx.fill();
        
        // 绘制数值标签（大幅增大字体）
        ctx.fillStyle = color;
        ctx.font = 'bold 22px sans-serif';
        ctx.textAlign = 'left';
        const labelX = x + 15;
        const labelY = y - 5;
        const tempUnitLabel = this.unitSystem === '国际单位' ? '°C' : '°F';
        ctx.fillText(`${temp.toFixed(1)}${tempUnitLabel}`, labelX, labelY);
      };
      
      // 绘制三个温度点标记（修正颜色）
      drawMarker(temps.hot, '#FF4444', '高温');
      drawMarker(temps.std, '#44BB44', '标准');
      drawMarker(temps.cold, '#4444FF', '低温');
    }
  }
}
