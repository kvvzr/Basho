import javax.swing.*;
import java.awt.*;
import java.awt.event.*;
import java.lang.reflect.*;

String[] showTypes = {"Integer", "Float", "Double", "Long", "Boolean", "String"};
int rowHeight = 30;
int margin = 8;
Insets insets;
int divideCount = 100;

public class Basho extends JFrame{
  private PApplet pApplet;
  private ViewPanel panel;
  private JScrollBar scrollBar;
  private Dimension panelSize;
  
  public Basho(PApplet pApplet){
    this.pApplet = pApplet;
    panelSize = new Dimension(400, 600);
    
    prepareLayout();
      
      new Thread(new RepaintThread()).start();
  }
  
  @Deprecated
  public void start(){
    /*new Thread(new Runnable() {
      @Override
      public void run() {
        while(true){
          repaint();
          try{
            Thread.sleep(10);
          }catch(Exception e){
          
          }
        }
      }
      }).start();*/
  }
  
  public void showValue(String name, Object value){
    Class<?> type = value.getClass();
    if (type.isArray()){
      panel.addArrayValue(name, value);
    }else{
      panel.addValue(value.getClass().getSimpleName(), name, value);
    }
  }
  
  public void removeValue(String name){
    panel.removeValue(name);
  }
  
  @Deprecated
  public void isShowArrayIndex(boolean isShow){
  
  }
  
  @Deprecated
  public void isShowDefaultValue(boolean isShow){
  
  }
  
  private class RepaintThread implements Runnable {
    @Override
    public void run() {
      int prevFrameCount = pApplet.frameCount;
      while(true){
        if (pApplet.frameCount != prevFrameCount){
          addGlobalValues();
          //max(ceil((float)(row * rowHeight - screenSize.height) / rowHeight), 0)
          int rc = panel.rowCount  + panel.rowCountOffset + 1;
          scrollBar.setMaximum((int)Math.max(Math.ceil((float)(rc * rowHeight - getHeight()) / rowHeight), 0));
          panel.rowCountOffset = scrollBar.getValue();
          repaint();
          prevFrameCount = pApplet.frameCount;
        }
        try{
          Thread.sleep(10);
        }catch(Exception e){
        
        }
      }
    }
  }
  
  private void prepareLayout(){
    pack();
    setTitle("Basho");
    setSize(panelSize.width, panelSize.height);
    
    panel = new ViewPanel();
    panel.setLayout(new BorderLayout());
    panel.setSize(panelSize.width, panelSize.height);
    add(panel);
    
    scrollBar = new JScrollBar();
      scrollBar.setMinimum(0);
      scrollBar.setMaximum(0);
      scrollBar.addAdjustmentListener(new AdjustmentListener(){
        public void adjustmentValueChanged(AdjustmentEvent e){
          //onPause = false;
        }
      }
      );
      add(scrollBar, BorderLayout.EAST);
    
    setVisible(true);
    
    insets = getInsets();
  }
  
  private void addGlobalValues(){
    Field[] fields = pApplet.getClass().getDeclaredFields();
    for (Field field : fields) {
      try{
        showValue(field.getName(), field.get(pApplet));
      }catch(Exception e){
        System.out.println(e);
      }
    }
  }
}

public class ViewPanel extends JPanel {
  private HashMap<String, Value> values;
  private ArrayList<String> rmValues;
  public int rowCount = 0;
  public int rowCountOffset = 0;
  
  public ViewPanel(){
    values = new HashMap<String, Value>();
    rmValues = new ArrayList<String>();
    fontMetrics = getFontMetrics(getFont());
    
    removeValue("showTypes");
    removeValue("rowHeight");
    removeValue("margin");
    removeValue("insets");
    removeValue("divideCount");
  }
  
  public void addValue(String type, String name, Object value){
    if (!values.containsKey(name)){
      if (!containsString(showTypes, type))
        return;
      values.put(name, new Value(name, value));
    }else{
      values.get(name).setValue(value);
    }
  }
  
  public void addArrayValue(String name, Object value){
    if (!values.containsKey(name)){
      String type = getArrayType(value);
      if (!containsString(showTypes, type))
        return;
      values.put(name, new ArrayValue(name, value));
    }else{
      values.get(name).setValue(value);
    }
  }
  
  public void removeValue(String name){
    if (!rmValues.contains(name))
      rmValues.add(name);
  }
  
  public int setScrollBar(int value){
    int result = rowCount + rowCountOffset;
    rowCountOffset = value;
    return result;
  }
  
  @Override
  protected void paintComponent(Graphics g) {
    int width = getWidth(), height = getHeight();
    
    g.setColor(new Color(255, 255, 255));
      g.fillRect(0, 0, width, height);
      
      int valueNameWidth = getMaxWidth(values.keySet().toArray(new String[0])) + margin * 2;
      rowCount = drawValues(g, valueNameWidth);
      g.setColor(new Color(0, 0, 0));
      g.drawLine(valueNameWidth, 0, valueNameWidth, height);
  }
  
  private int drawValues(Graphics g, int valueNameWidth){
    int rowCount = -rowCountOffset;
    
    for(String name : values.keySet()){
      if (!rmValues.contains(name))
        rowCount = values.get(name).draw(g, rowCount, getWidth(), valueNameWidth);
    }
    
    return rowCount;
  }
}

public class Value {
  protected String name;
  protected Object value;
  private Double prevValue;
  private Double maxValue;
  private ArrayList<Double> transition;
  private boolean isNumeric = false;
  
  public Value(String name, Object value){
    this.name = name;
    this.value = value;
    
    this.transition = new ArrayList<Double>();
    
    if (value instanceof Number){
      prevValue = Double.valueOf(value.toString());
      isNumeric = true;
      try{
        maxValue = Double.valueOf(value.toString());
      }catch(Exception e){}
    }
  }
  
  public void setValue(Object value){
    this.value = value;
  }
  
  public int draw(Graphics g, int rowCount, int width, int valueNameWidth){
    int y = rowCount * rowHeight + insets.top - 1;
    
    if (isNumeric && prevValue != null){
      double dValue = 0.0;
      try{
        dValue = Double.parseDouble(value.toString());
      }catch(Exception e){}
      
      maxValue = Math.max(Math.abs(dValue), maxValue);
      
      drawBackground(g, valueNameWidth, width, y, dValue, transition, maxValue);
      drawGraph(g, valueNameWidth, width, y, transition, maxValue);
      
      transition.add(dValue);
      prevValue = dValue;
    }
    
    drawValue(g, value.toString(), margin + valueNameWidth + insets.left, y);
    drawName(g, name, margin + insets.left, y);
    
    g.setColor(new Color(0, 0, 0));
    g.drawLine(0, y + margin, width, y + margin);
    return ++rowCount;
  }
  
  public void drawName(Graphics g, String name, int x, int y){
    g.setColor(new Color(0, 0, 0));
    g.drawString(name, x, y);
  }
  
  public void drawValue(Graphics g, String value, int x, int y){
    g.setColor(new Color(255, 255, 255));
    for(int i = -1; i < 2; i++){
      for(int j = -1; j < 2; j++){
        g.drawString(value, i + x, j + y);
      }
    }
    g.setColor(new Color(0, 0, 0));
    g.drawString(value, x, y);
  }
  
  public void drawGraph(Graphics g, int lx, int rx, int _y, ArrayList<Double> transition, double maxValue){
    for(int i = 0; i < transition.size(); i++){
      double e = (double)(rx - lx) / (divideCount - 1);
      int x = lx + insets.left + (int)(i * e);
      int y = _y + margin - rowHeight / 2;
      int l = Double.valueOf(((transition.get(i)) / maxValue) * rowHeight).intValue() / 2;
      
      if (l > 0){
        g.fillRect(x, y - l + 1, (int)e + 1, l);
      }else{
        g.fillRect(x, y + 1, (int)e + 1, -l);
      }
    }
  }
  
  public void drawBackground(Graphics g, int lx, int rx, int y, double dValue, ArrayList<Double> transition, double maxValue){
    if (transition.isEmpty())
      return;
    
    if (transition.size() > divideCount){
      transition.remove(0);
    }
    
    float sat = 0.0f;
    sat = (float)Math.abs(transition.get(0) / maxValue / 2);
    
    g.setColor(Color.getHSBColor(0.6f, 0.0f, 0.5f));
    
    double prevValue = transition.get(transition.size() - 1);
    if (dValue - prevValue > 0){
      g.setColor(Color.getHSBColor(0.0f, sat, 1.0f));
      g.fillRect(lx, y - rowHeight + margin + 1, rx - lx, rowHeight);
      g.setColor(Color.getHSBColor(0.0f, sat, 0.5f));
    }
    
    if (dValue - prevValue < 0){
      g.setColor(Color.getHSBColor(0.6f, sat, 1.0f));
      g.fillRect(lx, y - rowHeight + margin + 1, rx - lx, rowHeight);
      g.setColor(Color.getHSBColor(0.6f, sat, 0.5f));
    }
  }
}

public class ArrayValue extends Value {
  int dimention;
  int x, y, width, panelWidth;
  int rowCount, prevRowCount = 0;
  int[] sizeCount;
  int[] lenCount;
  int[] index;
  
  public ArrayValue(String name, Object value) {
    super(name, value);
    dimention = getDimention(value, 0);
    lenCount = new int[dimention];
    sizeCount = new int[countMaxLength(value, 0) + 1];
    index = new int[dimention];
    width = getMaxWidth();
  }
  
  @Override
  public int draw(Graphics g, int _rowCount, int width, int lx){
    rowCount = 0;
    panelWidth = width - lx;
    x = lx;
    y = _rowCount * rowHeight + insets.top - 1;
    
    initCount();
    drawFrame(g, x, y - rowHeight + margin, panelWidth);
    drawArrayValue(g, value, 0);
    
    g.setColor(new Color(0, 0, 0));
    for(int i = 0; i < rowCount - 1; i ++){
      g.drawLine(lx, y + margin + i * rowHeight, width, y + margin + i * rowHeight);
    }
    g.drawLine(0, y + margin + (rowCount - 1) * rowHeight, width, y + margin + (rowCount - 1) * rowHeight);
    
    drawName(g, name, margin + insets.left, y);
    prevRowCount = rowCount;
    return _rowCount + rowCount;
  }
  
  private void drawArrayValue(Graphics g, Object object, int depth){
    if (Array.get(object, 0).getClass().isArray()){
      for(int i = 0; i < Array.getLength(object); i++){
        index[depth] = i;
        drawArrayValue(g, Array.get(object, i), depth + 1);
      }
    }else{
      int len = Array.getLength(object);
          for(int i = 0; i < len; i++){
            index[depth] = i;
            String idx = "";
            for(int j = 0; j < dimention; j++){
              idx = idx + "[" + index[j] + "]";
            }
            idx = idx + " ";
            if (width < panelWidth){
              drawValue(g, idx + Array.get(object, i).toString(), x + i * panelWidth / len + margin, y + (rowCount) * rowHeight);
              g.setColor(new Color(0, 0, 0));
              g.drawLine(x + i * panelWidth / len, y + (rowCount - 1) * rowHeight, x + i * panelWidth / len, y + rowCount * rowHeight + margin);
            }else{
              drawValue(g, idx + Array.get(object, i).toString(), x + margin, y + rowCount * rowHeight);
              rowCount++;
            }
          }
          if (width < panelWidth){
            rowCount++;
          }
    }
  }
  
  private int counter;
  
  private void initCount(){
    for(int i = 0; i < sizeCount.length; i++){
      sizeCount[i] = 0;
    }
    countEachLength(value, 0);
  }
  
  private void countEachLength(Object object, int depth){
    if (Array.get(object, 0).getClass().isArray()){
      lenCount[depth] = Array.getLength(object);
      countEachLength(Array.get(object, 0), depth + 1);
    }else{
      if (width < panelWidth){
        lenCount[depth] = 1;
      }else{
        lenCount[depth] = Array.getLength(object);
      }
    }
  }
  
  private int countMaxLength(Object object, int depth){
    if (Array.get(object, 0).getClass().isArray()){
      return countMaxLength(Array.get(object, 0), depth + 1) * Array.getLength(object);
    }
    return Array.getLength(object);
  }
  
  private void drawFrame(Graphics g, int lx, int ly, int panelWidth){
    for(int i = 0; i < dimention - 1; i++){
      Graphics2D g2 = (Graphics2D)g;
      g2.setColor(Color.getHSBColor((float)i / dimention, 0.5f, 1.0f));
      g2.setStroke(new BasicStroke(2.0f));
      
      int size = lenCount[i];
      int sum = 1;
      for (int j = i + 1; j < dimention; j++){
        sum *= lenCount[j];
      }
      
      for(int j = 0; j < prevRowCount + 1; j++){
        if (j % sum == 0){
          sizeCount[j]++;
        }
      }
      
      for(int j = 0; j < prevRowCount / sum; j++){
        g2.drawRect(lx + i * 2 + 1, ly + sum * rowHeight * j + sizeCount[j * sum] * 2 - 1, panelWidth - i * 4 - 2, sum * rowHeight - (sizeCount[j * sum] + sizeCount[(j + 1) * sum]) * 2 + 2);
      }
      
      g2.setStroke(new BasicStroke(1.0f));
    }
  }
  
  private int getMaxWidth(){
    width = Math.max(getDeepestDimentionCount(value, 0) * 100, getDeepestDimentionTextWidth(value, 0));
    return width;
  }
  
  private int getDimention(Object object, int depth){
    if (Array.get(object, 0).getClass().isArray()){
      return getDimention(Array.get(object, 0), depth + 1);
    }
    return depth + 1;
  }
  
  private int getDeepestDimentionCount(Object object, int depth){
    if (Array.get(object, 0).getClass().isArray()){
      return getDeepestDimentionCount(Array.get(object, 0), depth + 1);
    }
    return Array.getLength(object);
  }
  
  private int getDeepestDimentionTextWidth(Object object, int depth){
    if (Array.get(object, 0).getClass().isArray()){
      return getDeepestDimentionTextWidth(Array.get(object, 0), depth + 1);
    }
    
    int width = 0;
    for (int i = 0; i < Array.getLength(object); i++){
      index[depth] = i;
          String idx = "";
        for(int j = 0; j < dimention; j++){
          idx = idx + "[" + index[j] + "]";
        }
        idx = idx + " ";
      width += getWidth(idx + Array.get(object, 0).toString()) + margin * 2;
    }
    return width;
  }
  
}

String getArrayType(Object object){
  if (Array.get(object, 0).getClass().isArray()){
    return getArrayType(Array.get(object, 0));
  }
  return Array.get(object, 0).getClass().getSimpleName();
}

FontMetrics fontMetrics;

int getMaxWidth(String[] strs){
  int maxWidth = 0;
      
  for(String str : strs){
    maxWidth = Math.max(maxWidth, fontMetrics.stringWidth(str));
  }
    
  return maxWidth;
}
  
int getWidth(String str){
  return fontMetrics.stringWidth(str);
}

boolean containsString(String[] strs, String str){
  for(String s : strs){
    if (s.equals(str))
      return true;
  }
  return false;
 }
  
