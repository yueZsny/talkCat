import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import '../components/pixel_cat.dart';

/// 像素猫猫展示页
class PixelCatDemoScreen extends StatefulWidget {
  const PixelCatDemoScreen({super.key});

  @override
  State<PixelCatDemoScreen> createState() => _PixelCatDemoScreenState();
}

class _PixelCatDemoScreenState extends State<PixelCatDemoScreen> {
  late PixelCatGame _game;

  @override
  void initState() {
    super.initState();
    _game = PixelCatGame(tileSize: 32);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF6F0),
      appBar: AppBar(
        title: const Text('像素猫猫'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            '🎨 等你画好精灵图放进来',
            style: TextStyle(fontSize: 14, color: Colors.grey[400]),
          ),
          const SizedBox(height: 4),
          Text(
            'assets/sprites/cat/cat_sheet.png',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[300],
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 24),

          // 像素猫展示区
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: GameWidget(game: _game),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            '🎨 粉色占位 = 等你画精灵图',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),

          const SizedBox(height: 24),

          // 规格说明
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '精灵图规格',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                _buildSpecLine('尺寸', '32×32 像素 / 帧'),
                _buildSpecLine('布局', '6 行 × 4 列'),
                _buildSpecLine('行0', '待机 idle（4帧循环）'),
                _buildSpecLine('行1', '走路 walk（4帧循环）'),
                _buildSpecLine('行2', '开心 happy（2帧）'),
                _buildSpecLine('行3', '难过 sad（2帧）'),
                _buildSpecLine('行4', '惊讶 surprised（1帧）'),
                _buildSpecLine('行5', '睡觉 sleep（2帧）'),
                const SizedBox(height: 12),
                Text(
                  '📖 画图指南: docs/pixel_cat_guide.md',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[400],
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSpecLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(value, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }
}
