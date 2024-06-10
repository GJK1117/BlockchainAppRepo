// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/**
    * @title New 러시안 룰렛
    * @author 2019136007 고진혁
    * @dev 이 계약은 참가자들이 회전식 권총의 방아쇠를 당기는 기존 러시안 룰렛 게임에 요금 지불 후 턴 넘기기, 재장전 등의 룰을 추가하였다.
    * @dev 참가자는 게임에 참여하기 위해 요금을 지불하고, 추가 요금을 지불하여 차례를 건너뛸 수 있으며, 재장전 요금을 지불하여 약실 내 총알의 위치를 초기화 할 수 있다.
    * @dev 마지막까지 살아남은 플레이어가 모든 상금을 가져간다.
    * @notice 상금 = 플레이어 참가비 + 턴을 넘기는 비용 + 재장전 비용
 */
contract RussianRoulette {
    //기본적으로 변수는 private 접근 지정자를 통해 외부에서 확인하지 못하도록 해주었다.
    //하지만 participantionFee, additionalFee, reloadFee 와 같이 비용 관련한 변수는 모두 public으로 설정하여 참가를 원하는 사용자가 해당 게임의 비용을 확인할 수 있도록 해주었다.
    //다른 변수나 배열의 경우 관리자와 플레이어의 접근을 구분해주기 위해 Getter 함수로 만들어 확인할 수 있게 해주었다.

    //게임을 관리하는 관리자의 주소를 저장할 변수이다.
    //관리자는 플레이어가 2명 이상 5명 이하로 참가하게 되면 게임을 시작할 수 있다.
    //또한, 현재 약실의 위치, 약실 내 총알의 위치, 플레이어 목록, 현재 턴의 플레이어, 총 상금 비용을 알 수 있다.
    //이것을 확인하는 함수들은 관리자만 확인할 수 있도록 modifier를 만들어 설정해주었다.
    address private manager;
    //게임에 참가하는 플레이어들의 주소를 저장할 배열이다.
    //게임에 참가하는 순서대로 플레이어의 주소값이 저장된다.
    //++ 동적 배열로 선언해주어 계약이 생성될 때 동적으로 플레이어의 수를 결정해주었다.
    //++ joinGame으로 플레이어가 게임에 참가하면 push 함수를 사용해 배열에 값을 넣어준다.
    address[] private players;

    //게임에 참가하기 위한 요금이다.
    //이는 관리자가 게임 시작 전에 결정할 수 있다, 이 비용에 맞춰 플레이어가 해당 금액을 지불하여 게임에 참가할 수 있다.
    //예를들어 게임 참가 비용이 1 이더이면 5명의 사용자가 참가하게 되면 총 5이더가 최종 상금에 누적된다.
    //++ 초기화를 하지 않은 uint 로 선언되었으므로 초기값은 0 이다.
    uint public participationFee;
    //턴을 건너뛰기 위한 추가 요금이다.
    //플레이어는 자신의 턴마다 1.방아쇠를 당긴다, 2.턴을 넘긴다, 3.재장전 총 3개의 선택을 할 수 있는데 2와 3은 추가 비용을 지불해야 한다.
    //이 비용 또한 관리자가 게임 시작 전에 비용을 결정할 수 있다.
    //그리고 이 비용은 게임 참가 비용에 더해져 최종 상금에 누적된다.
    uint public additionalFee;
    //재장전하기 위한 요금이다.
    //재장전을 할 때에도 추가 이더가 필요하다, 이 요금도 관리자가 게임 시작전에 결정할 수 있다.
    //이 비용도 participationFee, additionalFee 와 같이 최종 상금에 누적된다.
    uint public reloadFee;

    //현재 플레이어의 차례를 추적하는 인덱스이다.
    //게임에 참가하는 플레이어들의 주소가 저장된 players 배열에서 현재 턴의 사용자를 추적하기 위한 인덱스 값이다.
    //players 배열에 플레이어들이 차례대로 위치해있고, 턴이 넘어갈때마다 currentPlayerIndex 값이 1씩 증가해 옆 플레이어에게 턴이 넘어간다.
    //배열은 선형 자료구조이기 때문에 배열의 맨 끝에 도착하면 다시 배열의 처음으로 이동시키 위해 나머지 연산(%)을 수행해야 한다.
    //즉 참가자 수만큼 나머지 연산을 수행하여 턴이 순환되게 해주었다.
    uint private currentPlayerIndex;

    //약실의 상태를 저장하는 배열이다. (0: 비어 있음, 1: 총알 있음)
    //총 10개의 약실을 고정 크기 배열을 사용해 지정해주었다.
    //배열을 초기화하지 않았으므로 모든 요소는 0으로 설정된다.
    //++ 약실의 개수는 고정적이므로 동적 크기 배열 대신 고정 크기 배열을 사용하여 가스 비용을 절약하였다.
    //++ 고정 크기 배열은 동적 크기 배열에 반해 배열의 크기를 저장하고 관리하는 추가적인 가스 비용이 발생하지 않는다.
    uint[10] private chambers;
    //현재 약실의 위치를 추적하는 인덱스이다
    //chambers 배열의 위치를 나타내며, 현재 턴의 플레이어가 방아쇠를 당기면 chambers[chamberIndex] 값이 0 인지 1인지 확인하여 탈락여부를 결정한다.
    //플레이어가 방아쇠를 당겼는데 chamberIndex 위치의 약실에 총알이 있는 경우 해당 플레이어는 탈락하고, 반대의 경우에는 살아남아 턴을 넘길 수 있다.
    //실제 리볼버가 방아쇠를 당긴 후 약실이 한칸씩 옆으로 돌어가듯이 이 값도 한칸 씩 옆으로 이동되게 해주었다.
    //currentPlayerIndex 의 설명과 같이 이 값도 배열의 끝에서 처음으로 이동시키기 위해 나머지 연산을 수행해 약실이 순환되게 해주었다.
    uint private chamberIndex;
    //현재 약실에 있는 총알 수를 저장하는 변수이다.
    //처음 세팅은 플레이어수-1 개 이며, 방아쇠를 당겼을 때 chambers[chamberIndex] 가 1이면 총알이 발사된 것이므로 총알의 개수는 하나 줄어든다.
    uint private bullets;

    //게임이 시작되었는지 여부를 나타내는 값이다.
    //이 값을 통해 관리자가 지금 게임 중인지 아닌지 확인할 수 있다.
    //외부에서 확인할 수 있도록 public으로 설정해주었다.
    bool public gameStarted;

    //승자가 발생했을 때 발생하는 이벤트이다.
    //최종 승자가 나왔을 때 이를 확인할 수 있는 로그를 출력해준다.
    event Winner(string message, address winner);

    /**
        * @notice 생성자 : 계약을 초기화하고 초기 설정을 한다.
        * @notice 게임 참가 비용, 턴을 넘기기 위한 요금, 재장전 요금을 관리자 맘대로 설정할 수 있다.
        * @param _participationFee 게임에 참가하기 위한 요금
        * @param _additionalFee 턴을 넘기기 위한 추가 요금
        * @param _reloadFee 재장전하기 위한 요금
     */
    constructor(uint _participationFee, uint _additionalFee, uint _reloadFee) {
        //계약을 배포한 사용자의 주소를 관리자로 설정한다.
        //msg.sender : 솔리디티에서 제공하는 전역변수 중 하나이며 현재 호출한 주소를 나타낸다.
        //             이는 스마트 계약의 함수가 호출될 때마다 자동으로 설정되며, 호출자가 누구인지를 식별하는 데 사용된다.
        manager = msg.sender;
        //게임에 참가하기 위한 요금을 설정한다.
        participationFee = _participationFee;
        //턴을 넘기기 위한 요금을 설정한다.
        additionalFee = _additionalFee;
        //재장전 요금을 설정한다.
        reloadFee = _reloadFee;
        //게임은 아직 시작되지 않았고 배포만 되었으므로 false로 설정해준다.
        gameStarted = false;
    }

    /**
        * modifier는 함수의 실행을 수정하거나 제한하는 데 사용되는 특별한 구조이다. 이를 통해 특정 조건이 만족될 때만 함수가 실행되도록 할 수 있다.
        * 이 것을 통해 동일한 조건 검사를 여러 함수에 반복적으로 적용할 수 있어 코드의 재사용성을 높일 수 있다.
        * 또한, 조건 검사 로직과 실제 함수 로직을 분리하여 코드의 가독성을 높일 수 있으며
        * 조건 검사 로직을 변경해야 할때, 각 함수의 코드를 개별적으로 수정할 필요 없이 이 modifier만 수정하면 되므로 유지보수에도 용이하다.
        * 마지막으로 접근 제어를 보다 명확하게 정의할 수 있어, 의도치 않은 함수 호출을 방지할 수 있다.
    */
    //관리자만 호출할 수 있는 함수 수정자이다.
    modifier onlyManager() {
        //msg.sender가 manager와 같은지 확인한다.
        //같지 않다면 "Only manager can call this function"이라는 메시지와 함께 예외를 던진다.
        require(msg.sender == manager, "Only manager can call this function");
        //'_'는 수정자가 적용된 함수의 본문을 의미하며, 조건이 만족될 때 함수의 나머지 부분을 실행한다.
        _;
    }

    //플레이어만 호출할 수 있는 함수 수정자이다.
    modifier onlyPlayer() {
        //플레이어가 아닐 경우 예외를 던진다.
        //isPlayer 함수는 msg.sender가 players 배열에 있는지 확인한다.
        require(isPlayer(msg.sender), "Only players can call this function");
        //'_'는 수정자가 적용된 함수의 본문을 의미하며, 조건이 만족될 때 함수의 나머지 부분을 실행한다.
        _;
    }

    //특정 주소가 참가자인지 확인하는 내부 함수이다.
    function isPlayer(address _player) private view returns (bool) {
        //플레이어 배열을 순회하여 특정 주소가 있는지 확인한다.
        for (uint i = 0; i < players.length; i++) {
            //현재 순회 중인 플레이어의 주소가 _player와 같은지 확인한다.
            if (players[i] == _player) {
                return true; //같다면 true를 반환한다.
            }
        }
        return false; //배열을 끝까지 순회해도 없다면 false를 반환한다.
    }

    ///사용자가 게임에 참가하기 위해 호출하는 함수이다.
    //public 접근 지정자로 외부에서도 접근 가능하여 게임 참가를 원하는 사용자가 해당 함수를 호출하여 게임에 참가할 수 있다.
    //게임에 참가하기 위해서는 참가 비용을 내야 하므로 payable 키워드를 사용해주었다.
    //payable 키워드는 함수가 이더를 받을 수 있음을 나타낸다. payable 키워드가 없는 함수는 이더를 받을 수 없다.
    //payable 함수는 호출될 때 트랜잭션과 함께 msg.value에 전송된 이더의 양을 포함하여 호출된다.
    //이는 주로 스마트 계약의 자금을 관리하거나 특정 기능을 수행하는 데 사용되며 이 함수의 경우에는 게임에 참가하기위해 참가비를 지불하는 용도로 사용되었다.
    function joinGame() public payable {
        //게임이 이미 시작된 경우 예외를 던진다.
        require(!gameStarted, "Game has already started");
        //msg.value 의 값을 확인하고 관리자가 설정한 참가비용을 내지 않았을 경우 예외를 던진다.
        require(msg.value == participationFee, "Incorrect participation fee");
        //게임에 정상적으로 참가할 수 있는 경우 players 배열(참가자 명단)에 이 함수를 호출한 참가자의 주소를 push 해준다.
        players.push(msg.sender);
    }

    //게임을 시작하는 함수이다.
    //위에서 정의한 nolyManager modifier로 이 함수를 호출한 사용자가 관리자인지 검사하고 관리자일 경우만 이 함수의 본문을 실행한다.
    function startGame() public onlyManager {
        //참가한 플레이어의 수가 1명 이하면 예외를 던진다.
        require(players.length > 1, "Not enough players to start the game");
        //플레이어의 수가 충족되면 총알의 개수를 설정한다. 총알의 개수 = (플레이어 수 - 1)
        bullets = players.length - 1;
        //게임 시작 여부를 true 로 설정해준다.
        gameStarted = true;
        //첫번째 턴의 사용자를 정해준다. 이 게임에서는 제일 먼저 참여한 플레이어가 첫번째 턴을 가져가도록 설정해주었다.
        currentPlayerIndex = 0;
        //약실의 랜덤한 위치에 총알을 넣어주자.
        initializeChambers();
    }

    //총의 약실을 초기화하는 내부 함수이다.
    function initializeChambers() private {
        //고정 크기 배열인 chambers를 delete 키워드를 활용해 모두 0으로 초기화 해준다.
        delete chambers;
        //약실에 위치한 총알의 개수를 세는 변수이다. 모든 총알이 세팅되었는지 판단해주기 위해 선언하였다.
        uint bulletsPlaced = 0;
        //총 총알의 개수만큼 반복한다.
        while (bulletsPlaced < bullets) {
            //랜덤한 위치를 생성해준다.
            //솔리디티 자체에선 랜덤한 수를 생성은 지원하지 않기 때문에 블록 타입스탬프, 함수 호출 사용자 주소 등을 사용해 의사 랜덤 값을 생성한다.
            //먼저 abi.encodePacked 로 주어진 인수들을 바이트 배열로 인코딩한다.
            //그리고 이더리움 해시 함수인 keccak256 를 사용해 인코딩 된 데이터를 고정된 길이의 해시 값으로 변경해준다.
            //keccak256 으로 해싱된 값은 바이트 배열을 반환하므로 이것을 uint로 형변환 해준 후 10 으로 나머지 연산을 해주어 0~9 사이의 수를 얻는다.
            uint randomIndex = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, bulletsPlaced))) % 10;
            //약실에 총알이 들어있지 않다면 총알을 넣는다.
            //chambers안의 값이 0 이면 총알이 없는 것이고 1 이면 총알이 있는 것이다.
            //chambers[idx] 를 1로 설정하면 약실 내 idx 위치에 총알이 들어가는 것이다.
            if (chambers[randomIndex] == 0) {
                //총알을 넣어준다.
                chambers[randomIndex] = 1;
                //약실에 총알을 넣어줬으므로 해당 값을 1 증가 시켜준다.
                bulletsPlaced++;
            }
        }

        //처음 발사될 약실의 위치를 설정해준다.
        //ramdomIndex를 설정해준 것과 같이 0~9 랜덤 수를 뽑아준다.
        //리볼버에 총알을 넣고 약실을 한번 돌리고 멈췄을 때 총구방향에 위치하는 약실의 위치를 설정해준다고 이해하면 된다.
        //이 함수의 호출이 끝나고 플레이어가 방아쇠를 당겼을 때 해당 위치에 있는 약실에서 발사된다.
        chamberIndex = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 10;
    }

    //재장전하는 함수이다.
    //재장전을 할 경우에는 추가 이더를 지불해야하기 때문에 payable 키워드를 사용하였다.
    //또한, 관리자는 게임 상황만 확인하고 게임에는 직접 영향을 끼치지 못하게 해주기 위해 onlyPlayer modifier 로 참가자만 재장전을 할 수 있도록 해주었다.
    function reload() public payable onlyPlayer {
        //관리자가 설정한 재장전 비용을 지불하지 않았을 경우 예외를 던진다.
        require(msg.value == reloadFee, "Incorrect reload fee");
        //게임이 시작되지 않았을 경우 예외를 던진다.(플레이어가 게임이 시작되지 않았는데 재장전을 시도하는 것을 방지하기 위함이다.)
        require(gameStarted, "Game has not started yet");

        //initializeChambers 함수를 재사용해주었다.
        //게임 시작시 총의 약실을 초기화 하는 것과 동일하게 재장전 시에도 총의 약실을 다시 초기화해야한다.
        //실제 재장전할 때 총알을 다 빼고 랜덤한 위치에 총알을 다시 넣은 후 약실을 돌리는 것으로 이해하면된다.
        //이 함수를 통해 플레이어는 약실 내 총알의 위치와 현재 약실의 위치를 모두 초기화하여 다른 플레이어에게 혼동을 줄 수 있다.
        initializeChambers();
        //턴을 넘기는 함수를 호출한다.
        //재장전이 완료되면 다음 플레이어의 턴으로 넘어간다.
        nextTurn();
    }

    /**
        * 자신의 턴을 진행하는 함수이다.
        * 추가 이더를 지불하고 턴을 그냥 넘길수도 있으므로 payable 키워드를 사용해주었다.
        * 또한, 현제 플레이어의 턴에 관리자가 개입할 수 없도록 onlyPlayer modifier 로 접근을 제한하였다.
        * @param fire 매개변수로 bool fire를 받는다.(true : 방아쇠를 당긴다, false : 턴을 넘긴다(추가 이더 필요))
        * @return die 사용자가 탈락했는지 살아남았는지의 여부를 반환해준다.(true : 탈락, false : 생존)
    */
    function takeTurn(bool fire) public payable onlyPlayer returns (bool die) {
        //게임이 시작되지 않았을 경우 예외를 던진다.(플레이어가 게임이 시작되지 않았는데 턴을 진행하는 것을 방지하기 위함이다.)
        require(gameStarted, "Game has not started yet");
        //현재 턴이 아닌 사용자가 함수를 호출했을 경우 예외를 던진다.
        require(players[currentPlayerIndex] == msg.sender, "It's not your turn");

        //true일 경우 방아쇠를 던지는 로직을 수행한다.
        //false일 경우 턴을 넘기는 로직을 수행한다.
        if (fire) {
            //총알의 개수가 0개 이하이면 예외를 던진다.
            require(bullets > 0, "No bullets left in the chambers");
            //현재 약실에 총알이 들어있는 경우 수행한다.
            //즉 플레이어가 총에 맞아 탈락하는 경우 로직이다.
            if (chambers[chamberIndex] == 1) {

                //현재 플레이어는 탈락이므로 현재 플레이어 뒤의 턴에 위치한 플레이어들을 모두 한칸씩 앞으로 당겨준다.
                //예를들면, [A, B, C, D] 순으로 참가자가 위치했을 때 B 참가자가 자신의 턴에 총알에 맞았을 경우 B는 이제 신경쓰지 않아도 된다.
                //그래서 B 뒤에 위치하던 C, D를 한칸 씩 앞으로 옮겨준다. 아래 반복문을 수행하면 [A, C, D, D] 가 된다.
                //그런다음, pop 메소드를 통해 맨 뒤의 값을 지워주면 [A, C, D]가 되어 배열에서 순서를 유지한채 B 참가자만 빠지게된다.
                for (uint i = currentPlayerIndex; i < players.length - 1; i++) {
                    players[i] = players[i + 1];
                }
                //pop 메소드로 탈락한 플레이어를 배열에서 제거한다.
                players.pop();
                //총알이 하나 소모되었으므로 bullets 값을 하나 감소시킨다.
                bullets--;
                //현재 약실에 위치해있던 총알이 발사되었으므로 0으로 초기화해 총알이 없는 것을 표시해준다.
                chambers[chamberIndex] = 0;
                
                //만약 현재 플레이어가 1명만 남았을 경우엔 그 플레이어가 최종 승자가 되어 게임을 끝낸다.
                if (players.length == 1) {
                    //게임을 끝내는 함수를 호출해준다.
                    endGame();
                    return true;
                }

                //currentPlayerIndex가 마지막 플레이어인 경우에 처음 인덱스로 넘겨준다.
                //++ 여기서 nextTurn 함수를 재사용하지 않은 것은 현재 플레이어가 탈락하게 되면 players 배열에서 해당 플레이가 삭제되고 참가자의 수도 하나 줄어든다.
                //nextTurn은 currentPlayerIndex를 하나 증가 시키는 함수이다. 이 함수를 호출하게되면 한 플레이어의 턴을 스킵하게 되는데, 이는 한 플레이어가 탈락하면서 뒤의 플레이어들의 인덱스 값이 1씩 줄어들면서 생기는 문제이다.
                //예를들어 설명하면 [A, B, C, D] 이고 현재 플레이어는 B 이고 위치(currentPlayerIndex)는 1 이다.
                //B 가 탈락하면 [A, C, D] 가 되고 다음 턴은 C 가 되어야한다. 하지만 nextTurn 함수를 호출하면 currentPlayerIndex가 2 가 되버려서 다음 턴은 D 가 가져가버린다.
                //그래서 한명이 탈락했을 경우엔 currentPlayerIndex를 증가시키지 말아야한다.
                //또한 currentPlayerIndex가 players 배열의 끝 값일 경우엔 players 의 크기가 하나 줄어들기 때문에 다시 배열에 첫번째 위치한 플레이어에게 턴을 주기 위해 위치를 0으로 설정하여 예외를 처리해주었다.
                if (currentPlayerIndex >= players.length) {
                    currentPlayerIndex = 0;
                }
                //방아쇠를 당겼으므로 약실의 위치를 하나 옆으로 이동시켜준다.
                chamberIndex = (chamberIndex + 1) % 10;
                //플레이어가 탈락한 경우이므로 true를 반환한다.
                return true;
            }
            else {
                //턴을 넘기는 함수를 호출한다.
                nextTurn();
                //방아쇠를 당겼으므로 약실의 위치를 하나 옆으로 이동시켜준다.
                chamberIndex = (chamberIndex + 1) % 10;
                //플레이어가 탈락하지 않았으므로 false를 반환한다.
                return false;
            }
        } else {
            //플레이어가 턴을 건너뛰기 위해 추가 이더를 지불한다.
            //관리자가 설정한 턴을 넘기기위한 비용을 지불하지 않으면 예외를 던진다.
            require(msg.value == additionalFee, "Incorrect additional fee");
        }
        //턴을 넘기는 함수를 호출한다.
        nextTurn();
        //플레이어가 탈락하지 않았으므로 false를 반환한다.
        return false;
    }

    //다음 턴으로 넘기는 내부 함수이다.
    //currentPlayerIndex로 턴을 지정한다.
    function nextTurn() private {
        //currentPlayerIndex + 1 을 해주어 옆 플레이어에게 턴을 넘겨준다.
        //이때 배열은 선형 구조 이므로 나머지 연산을 통해 배열의 끝에 도달하면 배열의 처음으로 값을 설정해준다.
        currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    }

    //게임을 종료하는 내부 함수이다.
    function endGame() private {
        //최종 1인이면 players에 한 플레이어만 남게 된다.
        //이 플레이어의 주소를 winner 변수에 넣어준다.
        address winner = players[0];
        
        //우승한 플레이어에게 상금(이더)을 전송한다.
        //transfer 함수는 지정된 주소에 이더를 전송하는 함수이다.
        //payable(winner)로 winner 주소를 이더를 받을 수 있는 주소로 변환한다.
        //address(this).balance는 현재 계약의 전체 잔액을 나타낸다. 이 잔액이 지금끼자 쌓인 상금(게임참가비 + 턴 넘기기 비용 + 재장전 비용)이다.
        payable(winner).transfer(address(this).balance);
        //게임을 초기화하는 함수를 호출한다.
        resetGame();
        //우승자를 확인할 수 있도록 우승자를 로그에 표시해주기 위해 event를 발생시킨다.
        emit Winner("** Winner ** ", winner);
    }

    //게임을 초기 상태로 되돌리는 내부 함수이다.
    function resetGame() private {
        //게임에 참가한 플레이어들을 모두 삭제한다.
        delete players;
        //게임 시작 여부를 false로 설정한다.
        gameStarted = false;
    }

    //플레이어 목록을 반환하는 함수이다.
    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    //현재 턴의 플레이어 주소를 반환하는 함수이다.
    function getCurrentPlayer() public view returns (address) {
        //게임이 시작되지 않았을 경우 예외를 던진다.
        require(gameStarted, "Game has not started yet");
        return players[currentPlayerIndex];
    }

    //현재 약실의 상태를 확인할 수 있는 함수이다.
    //약실에 총알이 어디 위치해있는지 알 수 있다.
    //플레이어는 총알이 약실 어디에 위치해 있는지 알면 안되기 때문에 onlyManager modifier로 관리자만 접근가능하도록 설정해주었다.
    function getChamberState() public view onlyManager returns (uint[10] memory) {
        return chambers;
    }

    //현재 턴의 약실의 위치를 확인할 수 있는 함수이다.
    //플레이어는 현재 약실의 위치를 알면 안되기 때문에 onlyManager modifier로 관리자만 접근가능하도록 설정해주었다.
    function getChamberIndex() public view onlyManager returns (uint) {
        return chamberIndex;
    }
}