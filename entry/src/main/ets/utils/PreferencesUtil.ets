// Preferences工具类 - 用于数据持久化
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

// 单位换算设置接口
export interface UnitConverterSettings {
  selectedType: string;      // 当前选择的参数类型
  leftUnit: string;          // 左侧单位
  rightUnit: string;         // 右侧单位
  leftValue: string;         // 左侧输入值
}

export class PreferencesUtil {
  private static instance: PreferencesUtil;
  private preferences: preferences.Preferences | null = null;
  private readonly PREF_NAME = 'aerohub_preferences';
  
  // Keys for unit converter settings
  private readonly KEY_UNIT_CONVERTER_TYPE = 'unit_converter_type';
  private readonly KEY_UNIT_CONVERTER_LEFT_UNIT = 'unit_converter_left_unit';
  private readonly KEY_UNIT_CONVERTER_RIGHT_UNIT = 'unit_converter_right_unit';
  private readonly KEY_UNIT_CONVERTER_LEFT_VALUE = 'unit_converter_left_value';
  
  private constructor() {}
  
  // 获取单例实例
  public static getInstance(): PreferencesUtil {
    if (!PreferencesUtil.instance) {
      PreferencesUtil.instance = new PreferencesUtil();
    }
    return PreferencesUtil.instance;
  }
  
  // 初始化Preferences实例
  public async init(context: common.UIAbilityContext): Promise<void> {
    try {
      this.preferences = await preferences.getPreferences(context, this.PREF_NAME);
      console.info('[PreferencesUtil] Preferences initialized successfully');
    } catch (err) {
      console.error(`[PreferencesUtil] Failed to initialize preferences: ${JSON.stringify(err)}`);
    }
  }
  
  // 保存单位换算设置
  public async saveUnitConverterSettings(settings: UnitConverterSettings): Promise<void> {
    if (!this.preferences) {
      console.error('[PreferencesUtil] Preferences not initialized');
      return;
    }
    
    try {
      // 保存当前选择的参数类型
      await this.preferences.put(this.KEY_UNIT_CONVERTER_TYPE, settings.selectedType);
      
      // 保存当前参数类型的单位设置（使用参数类型作为key的一部分）
      const leftUnitKey = `${this.KEY_UNIT_CONVERTER_LEFT_UNIT}_${settings.selectedType}`;
      const rightUnitKey = `${this.KEY_UNIT_CONVERTER_RIGHT_UNIT}_${settings.selectedType}`;
      const leftValueKey = `${this.KEY_UNIT_CONVERTER_LEFT_VALUE}_${settings.selectedType}`;
      
      await this.preferences.put(leftUnitKey, settings.leftUnit);
      await this.preferences.put(rightUnitKey, settings.rightUnit);
      await this.preferences.put(leftValueKey, settings.leftValue);
      
      // 持久化到文件
      await this.preferences.flush();
      console.info(`[PreferencesUtil] Saved unit converter settings for ${settings.selectedType}`);
    } catch (err) {
      console.error(`[PreferencesUtil] Failed to save settings: ${JSON.stringify(err)}`);
    }
  }
  
  // 读取单位换算设置
  public async getUnitConverterSettings(selectedType: string): Promise<UnitConverterSettings | null> {
    if (!this.preferences) {
      console.error('[PreferencesUtil] Preferences not initialized');
      return null;
    }
    
    try {
      // 读取当前参数类型的单位设置
      const leftUnitKey = `${this.KEY_UNIT_CONVERTER_LEFT_UNIT}_${selectedType}`;
      const rightUnitKey = `${this.KEY_UNIT_CONVERTER_RIGHT_UNIT}_${selectedType}`;
      const leftValueKey = `${this.KEY_UNIT_CONVERTER_LEFT_VALUE}_${selectedType}`;
      
      const leftUnit = await this.preferences.get(leftUnitKey, '') as string;
      const rightUnit = await this.preferences.get(rightUnitKey, '') as string;
      const leftValue = await this.preferences.get(leftValueKey, '1') as string;
      
      // 如果没有保存过设置，返回null
      if (!leftUnit || !rightUnit) {
        return null;
      }
      
      return {
        selectedType: selectedType,
        leftUnit: leftUnit,
        rightUnit: rightUnit,
        leftValue: leftValue
      };
    } catch (err) {
      console.error(`[PreferencesUtil] Failed to get settings: ${JSON.stringify(err)}`);
      return null;
    }
  }
  
  // 获取上次使用的参数类型
  public async getLastSelectedType(): Promise<string> {
    if (!this.preferences) {
      console.error('[PreferencesUtil] Preferences not initialized');
      return 'length'; // 默认返回长度
    }
    
    try {
      const type = await this.preferences.get(this.KEY_UNIT_CONVERTER_TYPE, 'length') as string;
      return type;
    } catch (err) {
      console.error(`[PreferencesUtil] Failed to get last selected type: ${JSON.stringify(err)}`);
      return 'length';
    }
  }
}
