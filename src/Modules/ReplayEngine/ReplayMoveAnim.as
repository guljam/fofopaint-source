package Modules.ReplayEngine
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Sprite;

    // 이동 명령(move, move1, move2) 바로 앞 ["moveanim"]을 실시간 재생할때 보여주는 이동 애니메이션 (ReplayDrawer.moveAnim)
    // 이동 전 레이어 이미지를 새 Sprite 안의 Bitmap(실제 BitmapData를 참조만 함, 복사 없음)으로 보여주면서 목표 위치까지 감속하며 움직이고,
    // 끝나면 덮개를 치운 뒤 부르는 쪽이 실제 이동 명령을 실행함. 애니메이션 동안 레이어 데이터는 이동 전 그대로
    // 실제 레이어 Bitmap은 애니메이션 동안만 숨김, 숨기는 동안은 재생 중이라 캡처 같은 다른 동작이 끼어들 수 없고 clear가 반드시 복구함
    public class ReplayMoveAnim
    {
        private var container:Sprite = null;
        private var ref1:Bitmap = null; // 레이어1 이동 전 이미지, 실제 레이어 BitmapData를 참조만 함
        private var ref2:Bitmap = null;
        private var data1:BitmapData = null; // 참조한 BitmapData, 애니메이션 도중에 교체되거나 해제되지 않았는지 확인함
        private var data2:BitmapData = null;
        private var hidden1:Boolean = false; // 실제 레이어를 숨겼으면 true, 복구할 때까지
        private var hidden2:Boolean = false;
        private var savedVisible1:Boolean = true;
        private var savedVisible2:Boolean = true;
        private var moveLayer1:Boolean = false;
        private var moveLayer2:Boolean = false;
        private var distX:Number = 0;
        private var distY:Number = 0;
        private var totalMs:Number = 0;
        private var elapsedMs:Number = 0;
        private var lastUpdateMs:Number = 0; // 이미지를 마지막으로 움직인 때의 elapsedMs
        private var startCursorX:Number = 0; // 애니메이션 전 커서 위치, 중간에 끝나면 되돌림
        private var startCursorY:Number = 0;
        private var active:Boolean = false;

        public function get isActive():Boolean
        {
            return active;
        }

        // ["moveanim"] 칸을 읽은 직후에 불러야 함, 바로 다음 칸(이동 명령)에서 거리와 대상 레이어를 읽음
        // 애니메이션을 시작하지 못하면 false (그 이동은 바로 실행됨)
        public function start():Boolean
        {
            clear();
            const move:Array = ReplayDrawCommands.peekNext();

            if (!ReplayState.isMoveCommand(move))
            {
                return false;
            }

            distX = move[1];
            distY = move[2];
            totalMs = ReplayState.getMoveAnimMs(distX, distY);

            if ((distX === 0 && distY === 0) || !(totalMs > 0))
            {
                return false;
            }

            moveLayer1 = move[0] !== "move2";
            moveLayer2 = move[0] !== "move1";

            const layer1:Bitmap = ReplayDrawer.rCanvasLayer1Bitmap;
            const layer2:Bitmap = ReplayDrawer.rCanvasLayer2Bitmap;
            const show1:Boolean = layer1.visible && layer1.bitmapData !== null;
            const show2:Boolean = layer2.visible && layer2.bitmapData !== null;

            if (!show1 && !show2)
            {
                return false;
            }

            try
            {
                container = new Sprite();
                container.mouseEnabled = false;
                container.mouseChildren = false;

                // 실제와 같은 순서 (레이어2가 아래, 레이어1이 위), 움직이지 않는 레이어도 넣어서 순서가 어긋나지 않게 함
                if (show2)
                {
                    data2 = layer2.bitmapData;
                    ref2 = new Bitmap(data2, "auto", true);
                    container.addChild(ref2);
                }

                if (show1)
                {
                    data1 = layer1.bitmapData;
                    ref1 = new Bitmap(data1, "auto", true);
                    container.addChild(ref1);
                }

                // 리플레이 커서는 항상 맨 위라서 그 바로 아래에 넣음
                if (ReplayDrawer.rReplayFOFOCursor.parent === ReplayDrawer.rCanvasPanel)
                {
                    ReplayDrawer.rCanvasPanel.addChildAt(container, ReplayDrawer.rCanvasPanel.getChildIndex(ReplayDrawer.rReplayFOFOCursor));
                }
                else
                {
                    ReplayDrawer.rCanvasPanel.addChild(container);
                }

                // 덮개가 올라간 뒤에 실제 레이어를 숨겨서 한 프레임도 빈 화면이 나오지 않게 함, 배경은 rCanvasPanel이 자기 graphics로 그림
                if (show1)
                {
                    savedVisible1 = layer1.visible;
                    layer1.visible = false;
                    hidden1 = true;
                }

                if (show2)
                {
                    savedVisible2 = layer2.visible;
                    layer2.visible = false;
                    hidden2 = true;
                }
            }
            catch (error:Error)
            {
                clear();
                return false;
            }

            startCursorX = ReplayDrawCommands.getRCursorPos().x;
            startCursorY = ReplayDrawCommands.getRCursorPos().y;
            elapsedMs = 0;
            lastUpdateMs = 0;
            active = true;
            update(0);
            return true;
        }

        // dMs만큼 진행시킴. 끝났으면 덮개를 치우고 남은 시간(ms)을 돌려주고, 아직이면 -1
        // 끝나고 나면 부르는 쪽이 이동 명령을 실제로 실행해야 함
        public function advance(dMs:Number):Number
        {
            if (!active)
            {
                return dMs;
            }

            // 참조한 레이어 데이터가 바뀌었으면 (탐색, 캔버스 크기 변경 등) 애니메이션만 포기함, 상태는 프레임 위치대로 맞음
            if (!isReferenceValid())
            {
                clear();
                return dMs;
            }

            elapsedMs += dMs;

            // 리플레이 커서처럼 일정 주기로만 갱신함 (시간은 계속 흐르고 위치는 그 시간에 맞춰 한번에 따라잡음), 끝날때는 바로 마무리
            if (elapsedMs < totalMs && elapsedMs - lastUpdateMs < ReplayState.REPLAY_VISUAL_UPDATE_MS)
            {
                return -1;
            }

            lastUpdateMs = elapsedMs;

            if (elapsedMs >= totalMs)
            {
                const leftover:Number = elapsedMs - totalMs;
                clear(true);
                return leftover;
            }

            update(elapsedMs);
            return -1;
        }

        public function getRemainingMs():Number
        {
            return active ? Math.max(0, totalMs - elapsedMs) : 0;
        }

        // 덮개를 치우고 숨겼던 레이어를 복구함 (끝났을때, 일시정지, 탐색, 모드 탈출, 처음부터 다시 시작할때). 쉬고 있어도 불러도 됨
        // completed: 끝까지 흘러서 정상 종료. 이어서 실행될 이동 명령이 커서를 (현재 위치 + 이동 거리)로 옮기므로 그 기준이 되는 위치에 커서를 둠
        public function clear(completed:Boolean = false):void
        {
            const wasActive:Boolean = active;
            active = false;

            try
            {
                if (container)
                {
                    if (container.parent)
                    {
                        container.parent.removeChild(container);
                    }

                    // 참조만 끊음 (BitmapData는 실제 레이어 것이라 dispose하면 안 됨)
                    if (ref1)
                    {
                        ref1.bitmapData = null;
                    }

                    if (ref2)
                    {
                        ref2.bitmapData = null;
                    }
                }
            }
            finally
            {
                // 예외가 나도 실제 레이어는 반드시 복구함
                if (hidden1)
                {
                    ReplayDrawer.rCanvasLayer1Bitmap.visible = savedVisible1;
                }

                if (hidden2)
                {
                    ReplayDrawer.rCanvasLayer2Bitmap.visible = savedVisible2;
                }

                hidden1 = false;
                hidden2 = false;
                container = null;
                ref1 = null;
                ref2 = null;
                data1 = null;
                data2 = null;
            }

            if (wasActive)
            {
                if (completed)
                {
                    ReplayDrawCommands.setRCursorPosToCenter();
                }
                else
                {
                    ReplayDrawCommands.setRCursorPos(startCursorX, startCursorY);
                }
            }
        }

        // 숨긴 레이어가 이동 전 그대로 참조 중인 데이터인지
        private function isReferenceValid():Boolean
        {
            try
            {
                if (data1 && (ReplayDrawer.rCanvasLayer1Bitmap.bitmapData !== data1 || ReplayDrawer.rCanvasLayer1BitmapData !== data1 || data1.width <= 0))
                {
                    return false;
                }

                if (data2 && (ReplayDrawer.rCanvasLayer2Bitmap.bitmapData !== data2 || ReplayDrawer.rCanvasLayer2BitmapData !== data2 || data2.width <= 0))
                {
                    return false;
                }
            }
            catch (error:Error)
            {
                return false;
            }

            return true;
        }

        // 감속 이동 (ease-out): 처음에는 빠르고 끝에서 멈춤, 남은 시간 비율의 제곱만큼 덜 간 것으로 계산해서 시간에 정확히 맞고 정수 픽셀 위치
        // 이동하는 레이어는 이 위치로 옮기고 커서는 움직이는 비트맵(캔버스 크기)의 중앙에 둠
        private function update(ms:Number):void
        {
            const rest:Number = totalMs - ms;
            const remaining:Number = (rest * rest) / (totalMs * totalMs); // 아직 남은 거리 비율
            const offsetX:int = Math.round(distX * (1 - remaining));
            const offsetY:int = Math.round(distY * (1 - remaining));

            if (ref1 && moveLayer1)
            {
                ref1.x = offsetX;
                ref1.y = offsetY;
            }

            if (ref2 && moveLayer2)
            {
                ref2.x = offsetX;
                ref2.y = offsetY;
            }

            // 좌표만 바꾸고 아이콘 위치 갱신은 다른 명령처럼 진행바 타이머의 주기(startUpdatingPrograssBarTimer)에 맡김
            ReplayDrawCommands.setRCursorPos(ReplayState.RCANVAS_WIDTH / 2 + offsetX, ReplayState.RCANVAS_HEIGHT / 2 + offsetY);
        }
    }
}
