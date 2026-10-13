package Modules.L4UI
{
    import Modules.L4UI.UIEngine.WornBorderMask;
    import flash.display.DisplayObject;
    import flash.display.Sprite;

    // 층: L4 UI - SeekBarSet 트랙 막대의 가장자리를 손으로 그린 듯 해진 모양으로 자르는 마스크(WornBorderMask)를 소유함.
    // 트랙, 진행 막대, 삭제 범위 막대, 쉬는 구간 막대는 모두 트랙 사각형 안에 놓이므로 트랙 크기의 같은 모양 마스크를 각각 걸어서
    // 진행 막대 왼쪽 끝 등이 트랙과 같은 모양으로 해지게 함. 막대는 20x20을 width로 늘려 쓰기 때문에 마스크는 자식이 아니라 SeekBarSet에 형제로 둠
    public class SeekbarBorderUI
    {
        private static const SEEKBAR_TRACK_SEED:uint = 201;

        private const trackBarBorderMask:WornBorderMask = new WornBorderMask(SEEKBAR_TRACK_SEED);
        private const prograssBarBorderMask:WornBorderMask = new WornBorderMask(SEEKBAR_TRACK_SEED);
        private const deleteRangeBarBorderMask:WornBorderMask = new WornBorderMask(SEEKBAR_TRACK_SEED);
        private const replayWaitingRangeBarBorderMask:WornBorderMask = new WornBorderMask(SEEKBAR_TRACK_SEED);

        private const borderMaskList:Vector.<WornBorderMask> = new <WornBorderMask>[trackBarBorderMask, prograssBarBorderMask, deleteRangeBarBorderMask, replayWaitingRangeBarBorderMask];

        // 네 막대에 마스크를 달고 seekBarSet에 넣음. 트랙 위치와 크기는 updateTrackBorderRect로 맞춰야 함
        public function SeekbarBorderUI(seekBarSet:Sprite, trackBar:DisplayObject, prograssBar:DisplayObject, deleteRangeBar:DisplayObject, replayWaitingRangeBar:DisplayObject)
        {
            attachBorderMaskToBar(seekBarSet, trackBar, trackBarBorderMask);
            attachBorderMaskToBar(seekBarSet, prograssBar, prograssBarBorderMask);
            attachBorderMaskToBar(seekBarSet, deleteRangeBar, deleteRangeBarBorderMask);
            attachBorderMaskToBar(seekBarSet, replayWaitingRangeBar, replayWaitingRangeBarBorderMask);
        }

        // bar의 mask로 borderMask를 지정하고 seekBarSet에 형제로 넣음
        private function attachBorderMaskToBar(seekBarSet:Sprite, bar:DisplayObject, borderMask:WornBorderMask):void
        {
            seekBarSet.addChild(borderMask);
            bar.mask = borderMask;
        }

        //todo 세로가 바뀔때도 업데이트 안해주어야하는데 미세 최적화 할만한 가치가 있는지 의문
        // 네 마스크를 트랙 위치와 크기에 맞춤. 크기가 같으면 다시 그리지 않으므로 진행 막대 너비가 프레임마다 바뀌어도 부담이 없음
        public function updateTrackBorderRect(trackX:Number, trackY:Number, trackWidth:Number, trackHeight:Number):void
        {
            for each (var borderMask:WornBorderMask in borderMaskList)
            {
                borderMask.x = trackX;
                borderMask.y = trackY;
                borderMask.updateMaskSize(trackWidth, trackHeight);
            }
        }
    }
}
