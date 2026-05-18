// 单位换算页面
import router from '@ohos.router';
import { PreferencesUtil, UnitConverterSettings } from '../utils/PreferencesUtil';
import { common } from '@kit.AbilityKit';

interface ParameterType {
  label: string;
  value: string;
  units: string[];
}

interface SelectOption {
  value: string;
}

interface ConversionResult {
  value: string;
  unit: string;
}

// 换算因子数据结构（显式属性，避免索引签名报错）
interface FactorsData {
  length: Record<string, number>;
  speed: Record<string, number>;
  pressure: Record<string, number>;
  temperature: Record<string, number>;
  density: Record<string, number>;
  force: Record<string, number>;
  energy: Record<string, number>;
  power: Record<string, number>;
  angle: Record<string, number>;
  area: Record<string, number>;
  volume: Record<string, number>;
  mass: Record<string, number>;
  time: Record<string, number>;
  flow: Record<string, number>;
  massFlow: Record<string, number>;
}

class ConversionFactorsClass {
  length: Record<string, number> = {};
  speed: Record<string, number> = {};
  pressure: Record<string, number> = {};
  temperature: Record<string, number> = {};
  density: Record<string, number> = {};
  force: Record<string, number> = {};
  energy: Record<string, number> = {};
  power: Record<string, number> = {};
  angle: Record<string, number> = {};
  area: Record<string, number> = {};
  volume: Record<string, number> = {};
  mass: Record<string, number> = {};
  time: Record<string, number> = {};
  flow: Record<string, number> = {};
  massFlow: Record<string, number> = {};
}

// 参数类型与单位定义
const parameterTypes: ParameterType[] = [
  { label: '长度', value: 'length', units: ['m', 'km', 'dm', 'cm', 'mm', 'μm', 'nm', 'ft', 'in', 'yd', 'mi', 'nmi'] },
  { label: '速度', value: 'speed', units: ['m/s', 'km/h', 'km/s', 'ft/s', 'mph', 'knots', 'Mach'] },
  { label: '压力', value: 'pressure', units: ['Pa', 'hPa', 'kPa', 'MPa', 'bar', 'mbar', 'atm', 'psi', 'kgf/cm²', 'inHg', 'mmHg', 'Torr', 'mmH2O', 'inH2O'] },
  { label: '温度', value: 'temperature', units: ['K', '°C', '°F', '°R'] },
  { label: '密度', value: 'density', units: ['kg/m³', 'g/cm³', 'g/mL', 'kg/L', 'lb/ft³', 'lb/in³', 'slug/ft³'] },
  { label: '力', value: 'force', units: ['N', 'kN', 'kgf', 'tf', 'lbf', 'ozf', 'dyn', 'kip'] },
  { label: '能量', value: 'energy', units: ['J', 'kJ', 'Wh', 'kWh', 'cal', 'kcal', 'Btu', 'eV', 'erg', 'ft·lbf'] },
  { label: '功率', value: 'power', units: ['W', 'kW', 'MW', 'hp', 'PS', 'Btu/s', 'Btu/h', 'cal/s', 'ft·lbf/s'] },
  { label: '角度', value: 'angle', units: ['deg', 'rad', 'grad', 'arcmin', 'arcsec'] },
  { label: '面积', value: 'area', units: ['m²', 'km²', 'cm²', 'mm²', 'ha', 'acre', 'ft²', 'in²', 'yd²', 'mi²'] },
  { label: '体积', value: 'volume', units: ['m³', 'L', 'mL', 'cm³', 'ft³', 'in³', 'yd³', 'US gal', 'UK gal', 'bbl'] },
  { label: '质量', value: 'mass', units: ['kg', 'g', 'mg', 't', 'lb', 'oz', 'slug', 'ct', 'gr', 'long ton', 'short ton'] },
  { label: '时间', value: 'time', units: ['s', 'ms', 'μs', 'ns', 'min', 'h', 'day', 'week', 'month', 'year'] },
  { label: '流量', value: 'flow', units: ['m³/s', 'm³/h', 'L/s', 'L/min', 'L/h', 'ft³/s', 'ft³/min', 'US gal/min', 'UK gal/min'] },
  { label: '质量流量', value: 'massFlow', units: ['kg/s', 'kg/min', 'kg/h', 'lb/s', 'lb/min', 'lb/h', 'g/s', 'g/min', 't/h'] }
];

// 换算因子原始数据
const factorsData = {
  length: {
    'm': 1, 'km': 1000, 'dm': 0.1, 'cm': 0.01, 'mm': 0.001, 'μm': 1e-6, 'nm': 1e-9,
    'ft': 0.3048, 'in': 0.0254, 'yd': 0.9144, 'mi': 1609.344, 'nmi': 1852
  },
  speed: {
    'm/s': 1, 'km/h': 1/3.6, 'km/s': 1000, 'ft/s': 0.3048,
    'mph': 0.44704, 'knots': 0.514444, 'Mach': 340.3
  },
  pressure: {
    'Pa': 1, 'hPa': 100, 'kPa': 1000, 'MPa': 1e6, 'bar': 1e5, 'mbar': 100,
    'atm': 101325, 'psi': 6894.76, 'kgf/cm²': 98066.5,
    'inHg': 3386.39, 'mmHg': 133.322, 'Torr': 133.322,
    'mmH2O': 9.80665, 'inH2O': 249.0889
  },
  temperature: { 'K': 1, '°C': 1, '°F': 5/9, '°R': 5/9 },
  density: {
    'kg/m³': 1, 'g/cm³': 1000, 'g/mL': 1000, 'kg/L': 1000,
    'lb/ft³': 16.0185, 'lb/in³': 27679.9, 'slug/ft³': 515.379
  },
  force: {
    'N': 1, 'kN': 1000, 'kgf': 9.80665, 'tf': 9806.65,
    'lbf': 4.44822, 'ozf': 0.278014, 'dyn': 1e-5, 'kip': 4448.22
  },
  energy: {
    'J': 1, 'kJ': 1000, 'Wh': 3600, 'kWh': 3.6e6,
    'cal': 4.184, 'kcal': 4184, 'Btu': 1055.06,
    'eV': 1.60218e-19, 'erg': 1e-7, 'ft·lbf': 1.35582
  },
  power: {
    'W': 1, 'kW': 1000, 'MW': 1e6, 'hp': 745.7, 'PS': 735.49875,
    'Btu/s': 1055.06, 'Btu/h': 0.293071, 'cal/s': 4.184, 'ft·lbf/s': 1.35582
  },
  angle: {
    'rad': 1, 'deg': Math.PI / 180, 'grad': Math.PI / 200,
    'arcmin': Math.PI / 10800, 'arcsec': Math.PI / 648000
  },
  area: {
    'm²': 1, 'km²': 1e6, 'cm²': 0.0001, 'mm²': 1e-6,
    'ha': 10000, 'acre': 4046.86,
    'ft²': 0.092903, 'in²': 0.00064516, 'yd²': 0.836127, 'mi²': 2.58999e6
  },
  volume: {
    'm³': 1, 'L': 0.001, 'mL': 1e-6, 'cm³': 1e-6,
    'ft³': 0.0283168, 'in³': 1.63871e-5, 'yd³': 0.764555,
    'US gal': 0.00378541, 'UK gal': 0.00454609, 'bbl': 0.158987
  },
  mass: {
    'kg': 1, 'g': 0.001, 'mg': 1e-6, 't': 1000,
    'lb': 0.453592, 'oz': 0.0283495, 'slug': 14.5939,
    'ct': 0.0002, 'gr': 0.0000647989,
    'long ton': 1016.05, 'short ton': 907.185
  },
  time: {
    's': 1, 'ms': 0.001, 'μs': 1e-6, 'ns': 1e-9,
    'min': 60, 'h': 3600, 'day': 86400,
    'week': 604800, 'month': 2.628e6, 'year': 3.154e7
  },
  flow: {
    'm³/s': 1, 'm³/h': 1/3600,
    'L/s': 0.001, 'L/min': 1.66667e-5, 'L/h': 2.77778e-7,
    'ft³/s': 0.0283168, 'ft³/min': 0.000471947,
    'US gal/min': 6.30902e-5, 'UK gal/min': 7.57682e-5
  },
  massFlow: {
    'kg/s': 1, 'kg/min': 1/60, 'kg/h': 1/3600,
    'lb/s': 0.453592, 'lb/min': 0.00755987, 'lb/h': 0.000125998,
    'g/s': 0.001, 'g/min': 0.0000166667,
    't/h': 0.277778
  }
} as FactorsData;

// 构造换算因子实例
const conversionFactors: ConversionFactorsClass = new ConversionFactorsClass();
conversionFactors.length = factorsData.length;
conversionFactors.speed = factorsData.speed;
conversionFactors.pressure = factorsData.pressure;
conversionFactors.temperature = factorsData.temperature;
conversionFactors.density = factorsData.density;
conversionFactors.force = factorsData.force;
conversionFactors.energy = factorsData.energy;
conversionFactors.power = factorsData.power;
conversionFactors.angle = factorsData.angle;
conversionFactors.area = factorsData.area;
conversionFactors.volume = factorsData.volume;
conversionFactors.mass = factorsData.mass;
conversionFactors.time = factorsData.time;
conversionFactors.flow = factorsData.flow;
conversionFactors.massFlow = factorsData.massFlow;

@Entry
@Component
struct UnitConverter {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private typeScroller: Scroller = new Scroller();
  @State selectedType: string = 'length';
  @State leftValue: string = '1';
  @State rightValue: string = '';
  @State leftUnit: string = 'm';
  @State rightUnit: string = 'ft';
  @State showFormulaDialog: boolean = false;
  @State formulaFromUnit: string = 'm';
  @State formulaToUnit: string = 'ft';
  @State formulaResult: string = '';
  @State refreshFlag: number = 0;
  @State showResults: boolean = true;


  // 防止双向换算循环触发
  private skipRightChange: boolean = false;
  private skipLeftChange: boolean = false;
  // 防止单位切换时触发onFocus清空
  private preventFocusClear: boolean = false;
  // 记录当前活跃的输入端（'left' 或 'right'）
  private activeInput: 'left' | 'right' = 'left';
  // 保存设置的定时器
  private saveSettingsTimer: number | null = null;
  
  // 防抖保存设置
  private saveSettingsDebounced(): void {
    if (this.saveSettingsTimer) {
      clearTimeout(this.saveSettingsTimer);
    }
    this.saveSettingsTimer = setTimeout(async () => {
      try {
        await PreferencesUtil.getInstance().saveUnitConverterSettings({
          selectedType: this.selectedType,
          leftUnit: this.leftUnit,
          rightUnit: this.rightUnit,
          leftValue: this.leftValue
        });
      } catch (err) {
        console.error(`[UnitConverter] Failed to save settings: ${JSON.stringify(err)}`);
      }
    }, 500);
  }
  
  // 页面即将显示时加载保存的设置
  async aboutToAppear() {
    try {
      // 初始化Preferences
      await PreferencesUtil.getInstance().init(this.context);
      
      // 获取上次使用的参数类型
      const lastType = await PreferencesUtil.getInstance().getLastSelectedType();
      
      // 加载该参数类型的设置
      const settings = await PreferencesUtil.getInstance().getUnitConverterSettings(lastType);
      
      if (settings) {
        // 恢复保存的设置
        this.selectedType = settings.selectedType;
        this.leftUnit = settings.leftUnit;
        this.rightUnit = settings.rightUnit;
        this.leftValue = settings.leftValue;
        
        // 执行换算
        this.convertFromLeft();
        this.showResults = true;
      } else {
        // 如果没有保存的设置，使用默认值
        this.showResults = true;
        this.convertFromLeft();
      }
    } catch (err) {
      console.error(`[UnitConverter] Failed to load settings: ${JSON.stringify(err)}`);
      // 加载失败时使用默认值
      this.showResults = true;
      this.convertFromLeft();
    }
  }
  
  // 页面即将消失时保存当前设置
  async aboutToDisappear() {
    try {
      // 保存当前设置
      await PreferencesUtil.getInstance().saveUnitConverterSettings({
        selectedType: this.selectedType,
        leftUnit: this.leftUnit,
        rightUnit: this.rightUnit,
        leftValue: this.leftValue
      });
    } catch (err) {
      console.error(`[UnitConverter] Failed to save settings: ${JSON.stringify(err)}`);
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('单位换算')
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
          .onClick(() => { router.back(); })
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 8, bottom: 8 })
      .backgroundColor($r('app.color.primary_bg'))
      .alignItems(VerticalAlign.Center)

      // 横向滑动类型选择器
      Scroll(this.typeScroller) {
        Row({ space: 12 }) {
          ForEach(parameterTypes, (item: ParameterType) => {
            Text(item.label)
              .fontSize(14)
              .fontColor(this.selectedType === item.value ? $r('app.color.accent') : $r('app.color.secondary_text'))
              .fontWeight(this.selectedType === item.value ? FontWeight.Bold : FontWeight.Normal)
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .backgroundColor(this.selectedType === item.value ? $r('app.color.accent_light') : $r('app.color.card_bg'))
              .borderRadius(20)
              .onClick(async () => {
                this.preventFocusClear = true;
                this.activeInput = 'left';  // 切换类型时重置为左侧活跃
                
                // 保存当前参数类型的设置
                try {
                  await PreferencesUtil.getInstance().saveUnitConverterSettings({
                    selectedType: this.selectedType,
                    leftUnit: this.leftUnit,
                    rightUnit: this.rightUnit,
                    leftValue: this.leftValue
                  });
                } catch (err) {
                  console.error(`[UnitConverter] Failed to save settings: ${JSON.stringify(err)}`);
                }
                
                // 切换到新的参数类型
                this.selectedType = item.value;
                
                // 尝试加载新参数类型的设置
                try {
                  const settings = await PreferencesUtil.getInstance().getUnitConverterSettings(item.value);
                  if (settings) {
                    // 恢复保存的设置
                    this.leftUnit = settings.leftUnit;
                    this.rightUnit = settings.rightUnit;
                    this.leftValue = settings.leftValue;
                  } else {
                    // 如果没有保存的设置，使用默认值
                    this.leftUnit = item.units[0];
                    this.rightUnit = item.units[1] || item.units[0];
                    this.leftValue = '1';
                  }
                } catch (err) {
                  console.error(`[UnitConverter] Failed to load settings: ${JSON.stringify(err)}`);
                  // 加载失败时使用默认值
                  this.leftUnit = item.units[0];
                  this.rightUnit = item.units[1] || item.units[0];
                  this.leftValue = '1';
                }
                
                this.convertFromLeft();
                this.refreshFlag++;
                
                // 清除焦点，防止输入框自动获得焦点
                try {
                  this.getUIContext().getFocusController().clearFocus();
                } catch (err) {
                  console.error(`[UnitConverter] Failed to clear focus: ${JSON.stringify(err)}`);
                }
                
                // 延迟重置标志，确保后续点击能正常清空
                setTimeout(() => {
                  this.preventFocusClear = false;
                }, 100);
              })
          }, (item: ParameterType) => item.value)
        }
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .height(48)
      .backgroundColor($r('app.color.card_bg'))

      // 双输入区域
      Column() {
        Row() {
          Select(this.getCurrentUnits().map(unit => ({ value: unit } as SelectOption)))
            .value(this.leftUnit)
            .font({ size: 16 })
            .fontColor($r('app.color.primary_text'))
            .height(40)
            .borderRadius(4)
            .shadow({ radius: 0 })
            .backgroundColor($r('app.color.input_bg'))
            .layoutWeight(1)
            .onSelect(async (index: number, value: string) => {
              this.preventFocusClear = true;
              this.leftUnit = value;
              // 更换左侧单位时，保留左侧输入，换算右侧
              // 如果最后输入在左侧，从左侧换算到右侧
              // 如果最后输入在右侧，从右侧换算到左侧（保留右侧输入）
              if (this.activeInput === 'left') {
                this.convertFromLeft();
              } else {
                this.convertFromRight();
              }
              // 保存设置
              try {
                await PreferencesUtil.getInstance().saveUnitConverterSettings({
                  selectedType: this.selectedType,
                  leftUnit: this.leftUnit,
                  rightUnit: this.rightUnit,
                  leftValue: this.leftValue
                });
              } catch (err) {
                console.error(`[UnitConverter] Failed to save settings: ${JSON.stringify(err)}`);
              }
              // 延迟重置标志，确保后续点击能正常清空
              setTimeout(() => {
                this.preventFocusClear = false;
              }, 100);
            })

          Button('⇄')
            .fontSize(20)
            .fontColor($r('app.color.accent'))
            .width(50)
            .height(40)
            .backgroundColor(Color.Transparent)
            .borderRadius(4)
            .margin({ left: 8, right: 8 })
            .onClick(async () => {
              // 交换左右单位
              const tempUnit = this.leftUnit;
              this.leftUnit = this.rightUnit;
              this.rightUnit = tempUnit;
              
              // 重新换算
              if (this.activeInput === 'left') {
                this.convertFromLeft();
              } else {
                this.convertFromRight();
              }
              
              // 保存设置
              try {
                await PreferencesUtil.getInstance().saveUnitConverterSettings({
                  selectedType: this.selectedType,
                  leftUnit: this.leftUnit,
                  rightUnit: this.rightUnit,
                  leftValue: this.leftValue
                });
              } catch (err) {
                console.error(`[UnitConverter] Failed to save settings: ${JSON.stringify(err)}`);
              }
            })

          Select(this.getCurrentUnits().map(unit => ({ value: unit } as SelectOption)))
            .value(this.rightUnit)
            .font({ size: 16 })
            .fontColor($r('app.color.primary_text'))
            .height(40)
            .borderRadius(4)
            .shadow({ radius: 0 })
            .backgroundColor($r('app.color.input_bg'))
            .layoutWeight(1)
            .onSelect(async (index: number, value: string) => {
              this.preventFocusClear = true;
              this.rightUnit = value;
              // 更换右侧单位时，保留右侧输入，换算左侧
              // 如果最后输入在左侧，从左侧换算到右侧（保留左侧输入）
              // 如果最后输入在右侧，从右侧换算到左侧
              if (this.activeInput === 'left') {
                this.convertFromLeft();
              } else {
                this.convertFromRight();
              }
              // 保存设置
              try {
                await PreferencesUtil.getInstance().saveUnitConverterSettings({
                  selectedType: this.selectedType,
                  leftUnit: this.leftUnit,
                  rightUnit: this.rightUnit,
                  leftValue: this.leftValue
                });
              } catch (err) {
                console.error(`[UnitConverter] Failed to save settings: ${JSON.stringify(err)}`);
              }
              // 延迟重置标志，确保后续点击能正常清空
              setTimeout(() => {
                this.preventFocusClear = false;
              }, 100);
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 16 })

        Row() {
          TextInput({ text: this.leftValue })
            .fontSize(16)
            .height(36)
            .textAlign(TextAlign.End)
            .backgroundColor($r('app.color.input_bg'))
            .border({ width: 2, color: $r('app.color.accent') })
            .fontColor($r('app.color.primary_text'))
            .borderRadius(8)
            .padding({ left: 12, right: 12 })
            .layoutWeight(1)
            .placeholderColor($r('app.color.hint_text'))
            .onClick(() => {
              if (this.preventFocusClear) {
                this.preventFocusClear = false;
                return;
              }
              this.activeInput = 'left';
              this.leftValue = '';
              this.showResults = false;
            })
            .onChange((value: string) => {
              if (this.skipLeftChange) {
                this.skipLeftChange = false;
                return;
              }
              // 处理前导零问题
              let processedValue = value;
              if (value && value !== '0') {
                // 去除前导零，但保留小数点后的零（如0.5）
                processedValue = value.replace(/^0+(?=\d)/, '');
              }
              this.activeInput = 'left';
              this.leftValue = processedValue;
              this.convertFromLeft();
              if (processedValue !== '') this.showResults = true;
              // 保存设置（使用防抖，避免频繁保存）
              this.saveSettingsDebounced();
            })
            .onFocus(() => {
              if (this.preventFocusClear) {
                this.preventFocusClear = false;
                return;
              }
              this.activeInput = 'left';
              this.leftValue = '';
              this.showResults = false;
            })

          Blank().width(44)

          TextInput({ text: this.rightValue })
            .fontSize(16)
            .height(36)
            .textAlign(TextAlign.End)
            .backgroundColor($r('app.color.input_bg'))
            .border({ width: 2, color: $r('app.color.accent') })
            .fontColor($r('app.color.primary_text'))
            .borderRadius(8)
            .padding({ left: 12, right: 12 })
            .layoutWeight(1)
            .onClick(() => {
              if (this.preventFocusClear) {
                this.preventFocusClear = false;
                return;
              }
              this.activeInput = 'right';
              this.rightValue = '';
              this.showResults = false;
            })
            .onChange((value: string) => {
              if (this.skipRightChange) {
                this.skipRightChange = false;
                return;
              }
              // 处理前导零问题
              let processedValue = value;
              if (value && value !== '0') {
                // 去除前导零，但保留小数点后的零（如0.5）
                processedValue = value.replace(/^0+(?=\d)/, '');
              }
              this.activeInput = 'right';
              this.rightValue = processedValue;
              this.convertFromRight();
              if (processedValue !== '') this.showResults = true;
              // 保存设置（使用防抖，避免频繁保存）
              this.saveSettingsDebounced();
            })
            .onFocus(() => {
              if (this.preventFocusClear) {
                this.preventFocusClear = false;
                return;
              }
              this.activeInput = 'right';
              this.rightValue = '';
              this.showResults = false;
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 8 })
      .backgroundColor($r('app.color.card_bg'))

      Divider().strokeWidth(2).color($r('app.color.divider'))

      // 换算结果网格
      if (this.showResults) {
        Scroll() {
          Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Start }) {
            ForEach(this.getAllConversionResults(), (item: ConversionResult) => {
              Column() {
                Row() {
                  Text(item.value)
                    .fontSize(14)
                    .fontColor($r('app.color.accent'))
                    .fontWeight(FontWeight.Bold)
                    .textAlign(TextAlign.End)
                    .layoutWeight(1)
                    .maxLines(1)
                  Blank().width(6)
                  Text(item.unit)
                    .fontSize(14)
                    .fontColor($r('app.color.primary_text'))
                    .textAlign(TextAlign.Start)
                    .width(70)
                    .maxLines(1)
                }
                .width('100%')
                .padding({ left: 8, right: 8 })
              }
              .width('50%')
              .padding({ top: 8, bottom: 8 })
            }, (item: ConversionResult) => `${item.unit}-${this.refreshFlag}`)
          }
          .width('100%')
          .padding({ top: 8, bottom: 8 })
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .backgroundColor($r('app.color.card_bg'))
      }

      // 计算公式查询按钮
      Button('查询计算公式')
        .width('90%')
        .height(40)
        .fontSize(16)
        .backgroundColor($r('app.color.accent'))
        .margin({ top: 16, bottom: 16 })
        .onClick(() => {
          this.showFormulaDialog = true;
          this.formulaFromUnit = this.getCurrentUnits()[0];
          this.formulaToUnit = this.getCurrentUnits()[1] || this.getCurrentUnits()[0];
          this.calculateFormula();
        })

      // 计算公式查询对话框
      if (this.showFormulaDialog) {
        Stack() {
          Column()
            .width('100%')
            .height('100%')
            .backgroundColor(0x40000000)
            .backdropBlur(10)
            .onClick(() => { this.showFormulaDialog = false; })
          Column() {
            Text('计算公式查询')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.primary_text'))
              .margin({ top: 20, bottom: 16 })
            Row() {
              Text('从:').fontSize(16).fontColor($r('app.color.primary_text')).width(40)
              Select(this.getCurrentUnits().map(unit => ({ value: unit } as SelectOption)))
                .value(this.formulaFromUnit)
                .font({ size: 16 })
                .fontColor($r('app.color.primary_text'))
                .height(36)
                .backgroundColor($r('app.color.input_bg'))
                .layoutWeight(1)
                .onSelect((index: number, value: string) => {
                  this.formulaFromUnit = value;
                  this.calculateFormula();
                })
            }
            .width('80%')
            .margin({ bottom: 8 })
            Row() {
              Blank().layoutWeight(1)
              Button('⇄').width(65).height(36).fontSize(18).fontColor($r('app.color.accent')).backgroundColor(Color.Transparent).borderRadius(18)
                .onClick(() => {
                  const temp = this.formulaFromUnit;
                  this.formulaFromUnit = this.formulaToUnit;
                  this.formulaToUnit = temp;
                  this.calculateFormula();
                })
              Blank().layoutWeight(1)
            }
            .width('80%')
            .margin({ bottom: 8 })
            Row() {
              Text('到:').fontSize(16).fontColor($r('app.color.primary_text')).width(40)
              Select(this.getCurrentUnits().map(unit => ({ value: unit } as SelectOption)))
                .value(this.formulaToUnit)
                .font({ size: 16 })
                .fontColor($r('app.color.primary_text'))
                .height(36)
                .backgroundColor($r('app.color.input_bg'))
                .layoutWeight(1)
                .onSelect((index: number, value: string) => {
                  this.formulaToUnit = value;
                  this.calculateFormula();
                })
            }
            .width('80%')
            .margin({ bottom: 20 })
            Text(this.formulaResult)
              .fontSize(16)
              .fontColor($r('app.color.primary_text'))
              .textAlign(TextAlign.Center)
              .width('80%')
              .margin({ bottom: 20 })
            Row() {
              Button('关闭').width(100).height(36).fontSize(16).backgroundColor($r('app.color.accent'))
                .onClick(() => { this.showFormulaDialog = false; })
            }
            .width('100%')
            .justifyContent(FlexAlign.Center)
          }
          .width('80%')
          .padding(20)
          .backgroundColor($r('app.color.card_bg'))
          .borderRadius(8)
          .shadow({ radius: 10, color: '#000000', offsetX: 0, offsetY: 0 })
          .align(Alignment.Center)
        }
        .width('100%')
        .height('100%')
        .position({ x: 0, y: 0 })
      }

    }
    .width('100%')
    .height('100%')
    .onAppear(() => {
      this.showResults = true;
      this.convertFromLeft();
    })
  }

  private getCurrentUnits(): string[] {
    const type = parameterTypes.find(item => item.value === this.selectedType);
    return type ? type.units : ['m', 'ft'];
  }

  private convertFromLeft(): void {
    // 如果左侧为空，清空右侧但不触发换算
    if (this.leftValue === '') {
      this.skipRightChange = true;
      this.rightValue = '';
      return;
    }
    const val = this.convertValue(this.leftValue, this.leftUnit, this.rightUnit);
    this.skipRightChange = true;
    this.rightValue = val;
    if (this.showResults) this.refreshFlag++;
  }

  private convertFromRight(): void {
    // 如果右侧为空，清空左侧但不触发换算
    if (this.rightValue === '') {
      this.skipLeftChange = true;
      this.leftValue = '';
      return;
    }
    const valStr = this.convertValue(this.rightValue, this.rightUnit, this.leftUnit);
    const valNum = parseFloat(valStr);
    const leftNum = parseFloat(this.leftValue);

    // 如果反算结果与当前左侧值几乎相等（浮点误差），不更新左侧
    if (!isNaN(valNum) && !isNaN(leftNum) && Math.abs(valNum - leftNum) < 1e-4) {
      return;
    }

    this.skipLeftChange = true;
    this.leftValue = valStr;
    if (this.showResults) this.refreshFlag++;
  }

  private convertValue(valueStr: string, fromUnit: string, toUnit: string): string {
    if (valueStr === '') return '';
    const input = parseFloat(valueStr);
    if (isNaN(input)) return '0';

    let result: number;
    if (this.selectedType === 'temperature') {
      result = this.convertTemperature(input, fromUnit, toUnit);
    } else {
      let typeFactors: Record<string, number> | undefined;
      switch (this.selectedType) {
        case 'length': typeFactors = conversionFactors.length; break;
        case 'speed': typeFactors = conversionFactors.speed; break;
        case 'pressure': typeFactors = conversionFactors.pressure; break;
        case 'density': typeFactors = conversionFactors.density; break;
        case 'force': typeFactors = conversionFactors.force; break;
        case 'energy': typeFactors = conversionFactors.energy; break;
        case 'power': typeFactors = conversionFactors.power; break;
        case 'angle': typeFactors = conversionFactors.angle; break;
        case 'area': typeFactors = conversionFactors.area; break;
        case 'volume': typeFactors = conversionFactors.volume; break;
        case 'mass': typeFactors = conversionFactors.mass; break;
        case 'time': typeFactors = conversionFactors.time; break;
        case 'flow': typeFactors = conversionFactors.flow; break;
        case 'massFlow': typeFactors = conversionFactors.massFlow; break;
      }
      if (!typeFactors) return '0';
      const factorFrom = typeFactors[fromUnit];
      const factorTo = typeFactors[toUnit];
      if (factorFrom === undefined || factorTo === undefined) return '0';
      result = input * factorFrom / factorTo;
    }

    // 为角度单位添加特殊格式化
    if (this.selectedType === 'angle') {
      return this.formatAngleNumber(result);
    }

    return this.formatNumber(result);
  }

  private convertTemperature(value: number, fromUnit: string, toUnit: string): number {
    let kelvin: number;
    switch (fromUnit) {
      case 'K': kelvin = value; break;
      case '°C': kelvin = value + 273.15; break;
      case '°F': kelvin = (value - 32) * 5 / 9 + 273.15; break;
      case '°R': kelvin = value * 5 / 9; break;
      default: return value;
    }
    switch (toUnit) {
      case 'K': return kelvin;
      case '°C': return kelvin - 273.15;
      case '°F': return (kelvin - 273.15) * 9 / 5 + 32;
      case '°R': return kelvin * 9 / 5;
      default: return kelvin;
    }
  }

  private getAllConversionResults(): ConversionResult[] {
    const units = this.getCurrentUnits();
    const results: ConversionResult[] = [];
    for (let unit of units) {
      const conv = this.convertValue(this.leftValue, this.leftUnit, unit);
      results.push({ value: conv, unit: unit });
    }
    return results;
  }

  private formatNumber(num: number, maxDec: number = 6): string {
    if (Math.abs(num) < 1e-10 && num !== 0) return num.toExponential(4);
    if (Math.abs(num) > 1e10) return num.toExponential(4);
    let s = num.toFixed(maxDec);
    if (s.indexOf('.') !== -1) s = s.replace(/\.?0+$/, '');
    return s || '0';
  }

  private formatAngleNumber(num: number): string {
    const absNum = Math.abs(num);
    if (Math.abs(num - Math.round(num)) < 1e-10) {
      return Math.round(num).toString();
    }
    if (absNum < 0.01) {
      return num.toFixed(6).replace(/\.?0+$/, '');
    } else if (absNum < 1) {
      return num.toFixed(6).replace(/\.?0+$/, '');
    } else if (absNum < 10) {
      return num.toFixed(5).replace(/\.?0+$/, '');
    } else if (absNum < 100) {
      return num.toFixed(4).replace(/\.?0+$/, '');
    } else if (absNum < 1000) {
      return num.toFixed(3).replace(/\.?0+$/, '');
    } else {
      return num.toFixed(2).replace(/\.?0+$/, '');
    }
  }

  private calculateFormula(): void {
    const type = parameterTypes.find(item => item.value === this.selectedType);
    if (!type) {
      this.formulaResult = '请选择参数类型';
      return;
    }
    let factors: Record<string, number> | undefined;
    switch (this.selectedType) {
      case 'length': factors = conversionFactors.length; break;
      case 'speed': factors = conversionFactors.speed; break;
      case 'pressure': factors = conversionFactors.pressure; break;
      case 'temperature': factors = conversionFactors.temperature; break;
      case 'density': factors = conversionFactors.density; break;
      case 'force': factors = conversionFactors.force; break;
      case 'energy': factors = conversionFactors.energy; break;
      case 'power': factors = conversionFactors.power; break;
      case 'angle': factors = conversionFactors.angle; break;
      case 'area': factors = conversionFactors.area; break;
      case 'volume': factors = conversionFactors.volume; break;
      case 'mass': factors = conversionFactors.mass; break;
      case 'time': factors = conversionFactors.time; break;
      case 'flow': factors = conversionFactors.flow; break;
      case 'massFlow': factors = conversionFactors.massFlow; break;
      default: factors = undefined;
    }
    if (!factors) {
      this.formulaResult = '单位类型不支持';
      return;
    }
    const fromUnit = this.formulaFromUnit;
    const toUnit = this.formulaToUnit;
    if (fromUnit === toUnit) {
      this.formulaResult = `1 ${fromUnit} = 1 ${toUnit}`;
      return;
    }
    if (this.selectedType === 'temperature') {
      let formula = `1 ${fromUnit} = 1 ${toUnit}`;
      if (fromUnit === 'K' && toUnit === '°C') formula = '°C = K - 273.15';
      else if (fromUnit === 'K' && toUnit === '°F') formula = '°F = (K - 273.15) × 9/5 + 32';
      else if (fromUnit === 'K' && toUnit === '°R') formula = '°R = K × 9/5';
      else if (fromUnit === '°C' && toUnit === 'K') formula = 'K = °C + 273.15';
      else if (fromUnit === '°C' && toUnit === '°F') formula = '°F = (°C × 9/5) + 32';
      else if (fromUnit === '°C' && toUnit === '°R') formula = '°R = (°C + 273.15) × 9/5';
      else if (fromUnit === '°F' && toUnit === 'K') formula = 'K = (°F - 32) × 5/9 + 273.15';
      else if (fromUnit === '°F' && toUnit === '°C') formula = '°C = (°F - 32) × 5/9';
      else if (fromUnit === '°F' && toUnit === '°R') formula = '°R = °F + 459.67';
      else if (fromUnit === '°R' && toUnit === 'K') formula = 'K = °R × 5/9';
      else if (fromUnit === '°R' && toUnit === '°C') formula = '°C = (°R × 5/9) - 273.15';
      else if (fromUnit === '°R' && toUnit === '°F') formula = '°F = °R - 459.67';
      this.formulaResult = formula;
    } else {
      const factorFrom = factors![fromUnit];
      const factorTo = factors![toUnit];
      if (factorFrom === undefined || factorTo === undefined) {
        this.formulaResult = '单位不支持';
        return;
      }
      const conversionFactor = factorFrom / factorTo;
      const formattedFactor = this.formatNumber(conversionFactor, 6);
      this.formulaResult = `1 ${fromUnit} = ${formattedFactor} ${toUnit}`;
    }
  }
}