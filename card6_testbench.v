// 単位時間を1ナノ秒に設定
`timescale 1ns / 1ps

module card6_testbench;
  // テストベンチのモジュールにはポートリストはない
  parameter STEP = 10; // 10ナノ秒：100MHz
  parameter TICKS = 19;

  reg TEST_CLK;
  reg TEST_RESET;
  wire [17:0] TEST_ADRS;
  wire [ 5:0] TEST_DATA;

  // 各 initial ブロックは並列に実行される

  // シミュレーション設定
  initial
    begin
      // wave.vcd という名前で波形データファイルを出力
      $dumpfile("card6.vcd");
      // card6_1 に含まれる全てのポートを波形データに含める
      $dumpvars(0, card6_1);
      // シミュレータ実行時に card6_1 のポート adrs_bus と data_bus を
      // モニタする（値が変化した時に表示）
      $monitor("ADDR: %05x", card6_1.adrs_bus);
      $monitor("DATA: %02x", card6_1.data_bus);
    end

  // クロックを生成
  initial
    begin
      TEST_CLK = 1'b1;
      forever
        begin
          // #数値 で指定時間遅延させる
          // ~ でビット反転
          #(STEP / 2) TEST_CLK = ~TEST_CLK;
        end
    end

  // 同期リセット信号を生成
  initial
    begin
      TEST_RESET = 1'b0;
      // 2クロックの間リセット
      repeat (2) @(posedge TEST_CLK) TEST_RESET <= 1'b1;
      @(posedge TEST_CLK) TEST_RESET <= 1'b0;
    end

  // 指定クロックでシミュレーションを終了させる
  initial
    begin
      repeat (TICKS) @(posedge TEST_CLK);
      $finish;
    end

  // メモリ読み込み
  initial
    begin
      $readmemh("mem_c.txt",card6_1.mem_c.mem, 0, 262143);
      $readmemh("mem_a.txt",card6_1.mem_a.mem, 0, 262143);
      $readmemh("mem_r.txt",card6_1.mem_r.mem, 0, 262143);
      $readmemh("mem_d.txt",card6_1.mem_d.mem, 0, 262143);
    end

  // card6_1 という名前で CARD& CPU モジュールをインスタンス化
  card6 card6_1(.clock(TEST_CLK),.reset(TEST_RESET),.adrs_bus(TEST_ADRS),.data_bus(TEST_DATA));

endmodule 
