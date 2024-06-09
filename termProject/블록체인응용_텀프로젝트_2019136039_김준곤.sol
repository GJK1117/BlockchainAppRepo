// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// 한국기술교육대학교 컴퓨터공학부 2019136039 김준곤
// 블록체인응용 기말 텀프로젝트 : 블록체인을 사용한 게임 만들기

// 개 경주 게임의 진행 시 시나리오는 
// 1. 주최자에 의해 스마트 컨트랙트 배포
// 2. 게임 참가자들이 게임 시작 전 placeBet함수를 통해 개 이름으로 베팅, 베팅 금액은 사용자가 설정
// 3. 주최자가 startRace 함수를 실행하여 게임을 시작
// 4. 주최자가 endRace 함수를 실행하여 게임 종료 및 베팅 성공과 실패자를 구분하여 베팅금 분배
// 5. 다음 게임 준비
// 로 이루어져 있다.

// 개경주 게임을 구현한 스마트 컨트랙트, 예를 들면 JAVA의 Class와 같은 개념
// 내부에 개경주에 필요한 로직과 변수들이 선언되어 있음
// 내부 구조는 크게 상태 변수 정의, 이벤트 선언, 생성자 정의, 함수 정의 부분으로 나뉨
contract DogRace {
    // 변수 FINISH_LINE, raceId, owner, raceOngoing 등은 함수 밖에 선언된 상태 변수
    // 상태 변수로 선언 시 해당 스마트 컨트랙트 안 함수 내 어디든 선언이 가능하며 블록체인 상에 저장되어 영속성을 가짐
    // 상태 변수는 모두 private 접근 지정자를 사용하여 외부에서 쉽게 접근 불가하도록 설정

    // 게임 중 개의 단위 이동 거리를 나타내는 상수, 초기값은 100으로 설정
    // 고정된 값으로 수정되면 안되므로 constant로 선언
    // 이 값과 각 개들의 속도가 곱해져 이동거리를 계산하도록 함
    // uint256형로 선언하였으며 변수를 초기화하지 않을 경우 0으로 설정
    uint256 private constant FINISH_LINE = 100;
    // 현재 게임의 ID를 나타내는 변수, 초기값은 1로 설정
    // 매 게임을 구분 짓는 변수로 매 경기가 끝날 때 해당 변수가 증가
    // uint256형로 선언하였으며 변수를 초기화하지 않을 경우 0으로 설정
    uint256 private raceId = 1;
    // 컨트랙트를 배포한 소유자의 주소를 저장하는 변수, 초기값은 생성자를 통해 주입
    // 즉 주최자의 지갑 주소이며, 이를 저장하여 주최자만이 게임 주최 및 종료가 가능하도록 설정
    // 해당 주소를 통해 게임 내 수수료도 지급될 수 있음
    // address형을 사용해 선언했으며 address형 타입의 크기는 20bytes로 고정
    address private owner;
    // 게임이 진행 중인지 여부를 나타내는 변수, 초기 값은 false로 설정
    // 매 게임이 시작되면 true로 바뀌며, 게임이 종료되면 다시 false로 설정
    // bool형으로 선언되었으며, true, false 값을 가지며 주로 논리 연산자에 사용되어 조건을 통제
    bool private raceOngoing = false;

    // 개경주 게임에 참가한 개의 정보를 정의한 구조체
    // 개의 이동 속도 및 이동거리를 저장
    struct Dog {
        // 개의 이동 속도 변수, uint256형으로 선언, 초기화 안할 시 초기 값은 0
        uint256 speed;
        // 개의 이동 거리 변수, uint256형으로 선언, 초기화 안할 시 초기 값은 0
        uint256 distance;
    }

    // 베팅 정보를 저장하는 구조체
    // 베팅 금액 및 베팅한 개 이름 저장
    struct Bet {
        // 베팅 금액 변수, uint256형으로 선언, 초기화 안할 시 초기 값은 0
        uint256 amount;
        // 베팅한 개 이름 변수, string형으로 선언, 동적 크기 UTF-8로 인코딩된 배열
        string dogName;
    }

    // 개의 이름들을 저장하는 배열, 7마리의 개 이름을 지정하므로 size는 7로 설정
    // 사용자는 가장 빨리 완주할 수 있는 개를 골라야 승리할 수 있음. 승리와는 무관하나 이름이 빨라 보이면 선택하는 재미가 있을 것이라 생각하여 설정
    // 실제로 개 이름을 지정할 때 속도와 관련된 단어를 선택해서 설정
    // string형 배열을 선언해서 설정, 각 배열 위치에는 string형의 개 이름이 설정
    string[7] private dogNames = ["Flash", "Bolt", "Zoom", "Rocket", "Speedy", "Blaze", "Dash"];
    // 개 이름을 번호로 매핑
    // string형의 문자로 지정된 개 이름을 개 번호와 매치 되도록 mapping을 사용하여 매치
    // 이 부분의 구현은 사실 개의 정보가 저장된 Dog 구조체에 선언해도 될 것으로 생각되나 동작 상에는 문제가 없고 chatGPT가 처음 지정해준 코드여서 그대로 사용
    // 생성자에서 초기 값이 결정되며, dogNanems 배열에 저장된 이름을 순서대로 1~7번으로 매치
    mapping(string => uint8) private dogNamesToNumbers;
    // 번호로 개 정보 구조체를 매핑
    // 개는 각 번호가 존재하는데, 그 번호를 지정했을 때 해당 개 정보가 담긴 구조체를 바로 가리키도록 매핑 코드 작성
    // 이를 통해 구조체를 불러오기 용이해지고, dogNamesToNumbers 매핑과 연계해서 string형으로 개 이름이 들어왔을 때 바로 구조체를 매핑하는 구조로도 사용이 가능
    // dogsNamesToNumbers 매핑과 같이 생성자에서 초기화되며, 매핑에 초기화되는 개 정보 구조체의 초기 값은 모두 0으로 지정될 것임
    mapping(uint8 => Dog) private dogs;
    // 주소로 베팅 정보를 매핑
    // 게임 참여자의 지갑 주소를 address로 정의, 이 주소를 각 베팅 정보 구조체와 매치하도록 매핑
    // 게임 시작 전 게임 참가자들이 베팅할 떄 초기화되어 사용자의 베팅 정보를 관리
    mapping(address => Bet) private bets;
    // 베팅한 사람들의 지갑 주소를 저장하는 배열
    // 게임에 참여한 사람들의 목록을 기록, 해당 주소는 베팅 정보 구조체와 연관이 있기 때문에 게임 베팅 승리자를 가려내는 데 사용
    // address형 배열로 선언, 배열에 값을 추가할 때는 push함수를, 배열을 초기화할 때는 delete를 사용
    address[] private betters;
    // 전체 베팅 금액을 저장하는 변수
    // 게임 참여자들이 게임에 베팅한 총 금액을 계산하여 저장하고, 이를 베팅 승리자에게 배분될 떄 사용
    // uint256형 변수로 선언, 초기화 안 할시 초기 값은 0
    uint256 private totalBetAmount;


    // 여기부터 event 선언 부분
    // event는 블록체인 상에 로그를 남기는 기본 문법, 해당 스마트 컨트랙트에서는 크게 경주 시작, 경주 끝, 베팅이 성사되었을 때 이 3가지 경우가 중요하며 이를 로그에 남기도록 event를 선언
    // 선언한 이벤트는 각 로직의 함수에 emit으로 event 실행
    // event를 사용함으로서 비교적 적은 가스 비용으로 데이터를 저장을 할 수 있고, 만약 블록체인이 front-end와 연동되어 서비스가 운영된다면 front-end와의 데이터 송수신이 용이

    // 경주가 시작되었을 때 발생하는 event
    // RaceStarted event의 매개 변수로 uint256형의 raceId가 선언, 해당 정보가 로그에 포함
    // startRace 함수에서 해당 event가 실행되어 로그를 남김
    event RaceStarted(uint256 raceId);
    // 경주가 끝났을 때 발생하는 event
    // RaceEnded event의 매개 변수로 uint256형의 raceId와 string형의 winningDog가 선언, 해당 정보가 로그에 포함
    // endRace 함수에서 해당 event가 실행되어 로그를 남김
    event RaceEnded(uint256 raceId, string winningDog);
    // 베팅이 성사되었을 때 발생하는 event
    // BetPlaced event의 매개 변수로 address형의 better, uint256형의 amount, string형의 dogName를 선언, 특히 better 앞에 수식된 indexed 키워드는 해당 event를 조회하게 될 때 저 값이 인덱스화되어 검색하기 용이하게 함
    // indexed 키워드는 사실 있어도 없어도 실행에는 문제가 없으나 나중에 event를 조회하게 될 때 차이가 있는 것임
    // placeBet 함수에서 해당 event가 실행되어 로그를 남김
    event BetPlaced(address indexed better, uint256 amount, string dogName);


    // 여기부터 생성자 정의 부분
    // 생성자 함수, 컨트랙트가 배포될 때 실행되어 상태 변수를 초기화하거나 초기 컨트랙트에 필요한 로직을 수행
    // constructor를 사용하여 생성자 함수 선언, 주최자의 정보(지갑 주소)를 초기값으로 설정
    // 또한 for문을 사용해서 개의 번호와 이름을 매핑하도록 배열을 초기화, 나중에 이름을 통해 개 번호에 접근할 수 있도록 함
    constructor() {
        // 컨트랙트를 배포한 사람의 지갑 주소를 owner로 설정
        // 여기서 사용된 msg는 solidity의 전역 변수로 해당 컨트랙트에 요청된 트랜잭션의 정보를 담고 있는 객체

        // msg 객체를 통해 알 수 있는 정보들 : 
        // msg.sender : 트랜잭션을 보낸 주소, 즉 함수 호출을 시작한 주체의 지갑 주소
        // msg.value : 트랜잭션과 함께 전송된 이더(ETH)의 양
        // msg.data : 함수 호출과 함께 전송된 데이터
        owner = msg.sender;
        
        // 반복문을 통해 개 정보와 관련한 dogNamesToNumbers, dogs 매핑을 초기화
        // 이때 인덱스로 uint8로 선언한 i 변수 사용하여 0~6까지 인덱스를 순회, 작은 값이기에 uint256같은 자료형을 사용하지 않아도 충분
        // 인덱스 i가 하나씩 증가하는 증감연산자를 사용하여 1씩 커져가며 6까지 순회
        for (uint8 i = 0; i < 7; i++) {
            // 개 이름을 번호에 매핑
            // 앞서 선언한 개 이름 배열 dogNames를 인덱스 i로 순회하며 dogNamesToNumbers에 i+1 값과 매핑하도록 초기화
            // 예를 들어 dogNames 배열의 0번째 값은 정수 값 1과 매치되고 5번쨰 값은 정수 값 6과 매치
            dogNamesToNumbers[dogNames[i]] = i + 1;

            // 개 번호를 개 정보 구조체 Dog에 매핑
            // 개 정보 구조체 Dog는 초기 값이 speed : 0, distance : 0으로 나중에 게임이 시작되면 값이 설정, 구조체는 {}로 바로 초기화하며 매핑
            // 번호 1~7번이 각각 7개의 Dog 구조체에 매핑
            dogs[i + 1] = Dog({speed: 0, distance: 0});
        }
    }

    // 여기서부터 모디파이어 및 함수 선언 부분

    // 오직 소유자만 호출할 수 있는 모디파이어, solidity에서 기본적으로 제공하는 모디파이어가 아닌 프로그래머가 임의로 선언한 모디파이어
    // 게임 시작과 종료는 주최자만 가능하므로 해당 모디파이어를 사용하여 이를 통제 가능
    // startRace, endRace 함수에 붙어 기능을 통제
    modifier onlyOwner() {
        // 모디파이어 내용 구성으로 오류 처리 내용을 구현, require 함수로 오류 처리 내용 구현
        // 모디파이어가 수식하는 함수 호출자가 주최자인지 확인하는 로직이 필요
        // msg.sender == owner일 경우에만 적절하게 동작하는 것. msg.sender != owner일 경우는 호출자 주체가 주최자가 아니므로 require문 안의 왼쪽 문자열이 오류 메시지로 반환
        // require 함수는 오류 발생 시 가스비를 반환하므로 오류 발생 자체에 문제를 고려할 필요가 없음
        require(msg.sender == owner, "Only owner can call this function");
        // 해당 코드의 의미는 해당 코드(_;) 위치부터 모디파이어가 수식하는 함수 내용이 실행된다는 것
        // 예를 들어 onlyOwner 모디파이어가 수식하는 startRace 함수가 있을 때, require 함수 동작 이후에 startRace 함수가 실행된다는 의미
        _;
    }

    // 경주가 진행 중이지 않을 때만 호출할 수 있는 모디파이어, solidity에서 기본적으로 제공하는 모디파이어가 아닌 프로그래머가 임의로 선언한 모디파이어
    // 게임이 시작될 때 실행되면 게임 상 오류가 있을 수 있는 부분을 통제 가능
    // placeBet, startRace 함수에 붙어 기능을 통제
    modifier raceNotOngoing() {
        // 모디파이어 내용 구성으로 오류 처리 내용 구현, require 함수로 오류 처리 내용 구현
        // 게임이 진행 중인지 확인하는 로직 필요
        // 게임이 진행 중인지 기록하는 bool형 변수 raceOngoing가 false여야 게임이 진행 중이 아니므로 정상 진행 가능하고, true인 경우 이미 진행된 게임이 있다는 의미이므로 오류 메시지를 반환
        // require 함수 매개 변수 중 왼쪽의 있는 내용의 조건이 false일 때 오른쪽 매개 변수인 오류 메시지가 반환
        // 따라서 게임 진행 중인 true일 경우 !연산자에 의해 반전되어 false가 되어 오류 메시지가 반환
        require(!raceOngoing, "Race is already ongoing");
        // 해당 코드의 의미는 해당 코드(_;) 위치부터 모디파이어가 수식하는 함수 내용이 실행된다는 것
        _;
    }

    // 경주를 시작하는 함수, 오직 소유자만 호출 가능하며, 경주가 진행 중이지 않아야 함
    // 해당 함수는 게임 진행에 중요한 함수이므로 public으로 컨트랙트 외부에서 접근 가능하도록 함
    // 모디파이어는 한 함수에 여럿 붙여 사용 가능, 주최자일 경우와 게임이 시작되지 않았을 때만 함수 실행이 가능하므로 모디파이어 두 개 조합으로 해당 조건 실현 가능
    function startRace() public onlyOwner raceNotOngoing {
        // 해당 함수 실행은 경주 시작을 의미하므로 경주 상태를 진행 중으로 변경, true로 설정
        // 이 함수 실행 후부터 raceNotOngoing 모디파이어가 수식된 함수는 실행 불가능
        raceOngoing = true;
        // for문을 사용하여 7마리 개들의 각각 이동 속도를 랜덤하게 설정
        // uint8형의 i변수를 사용하여 1~7까지의 정수를 순회, 증감연산자를 통해 1씩 커지며 순회
        for (uint8 i = 1; i <= 7; i++) {
            // 각 개의 속도를 무작위로 설정 (1~10), 무작위 값을 선정하는 과정은 다음과 같음
            // 1. 무작위로 설정하는 매개 변수로 block의 타임스탬프를 기록하는 block.timestamp를 사용
            // 2. block.timestamp와 인덱스 i를 abi.encodePacked의 매개 변수로 전달하여 단일 바이트 배열로 변환
            // 3. keccak256 해시 함수를 사용하여 인코딩된 바이트배열을 256비트 해시값으로 변환
            // 4. 해시값을 uint256으로 변환, 이렇게 되면 굉장히 큰 수가 반환
            // 5. 1~10의 값을 랜덤으로 가지려고 하므로, %10 연산을 통해 0~9까지 값으로 변환하고, +1을 통해 1~10 범위의 값을 도출
            // 이 과정을 통해 예측할 수 없는 uint256형의 변수를 나머지 연산하여 계산함으로서 랜덤한 수를 계산할 수 있음, 해당 랜덤 값을 dogs에 매핑된 구조체 값 speed에 저장
            dogs[i].speed = (uint256(keccak256(abi.encodePacked(block.timestamp, i))) % 10) + 1;
            // 각 개의 거리를 0으로 초기화, 초기에는 이동거리가 없기 때문
            dogs[i].distance = 0;
        }
        // 경주 시작 event 발생, raceId 매개 변수 전달
        // emit 키워드를 사용하여 event 발생
        emit RaceStarted(raceId);
    }

    // 베팅을 하는 함수, 경주가 진행 중이지 않을 때만 호출 가능
    // 해당 함수는 게임 진행에 중요한 함수이므로 public으로 컨트랙트 외부에서 접근 가능하도록 함
    // payable는 이더의 송수신을 돕는 역할을 함, 이 함수를 통해 게임 참가자의 이더를 받아야 하므로 해당 키워드가 수식되어야 함
    // 또한 이 함수는 게임 시작 전에 실행되어야 하므로 raceNotOngoing 모디파이어가 붙어 조건을 실현
    // 매개 변수에 memory 수식어를 추가하여 함수 실행 시간동안만 dogName을 저장하도록 함
    function placeBet(string memory dogName) public payable raceNotOngoing {
        // 개 이름에 해당하는 번호를 dogNamesToNumbers 매핑을 통해 가져옴
        // uint8형으로 변수 선언하여 자료형 통일
        // 매핑에 없는 키값을 조회할 경우 기본 값이 0이 반환, 이를 통해 유효한 개의 경우만 처리 가능
        uint8 dogNumber = dogNamesToNumbers[dogName];

        // 오류 처리 내용, require 함수를 사용
        // 유효한 개 이름인지 확인, 매핑 시에 기본 값 0이 반환되었다는 것은 존재하지 않는 키(개 이름)으로 매핑을 조회한 것이므로 오류 처리
        // dogNumber == 0인 경우 오류 메시지 반환
        require(dogNumber != 0, "Invalid dog name");
        // 베팅 금액이 0보다 큰지 확인, 0원을 걸고 게임하는 것은 게임 진행 상 리스크 없는 행동이므로 금지
        // 이더 금액을 확인하기 위해 msg.value를 사용하고, msg.value <= 0 일 경우 오류 메시지 반환
        require(msg.value > 0, "Bet amount must be greater than 0");

        // 베팅한 이력이 없는 경우를 확인
        // bets 매핑에 없는 키 값으로 조회할 경우 0이 반환, 그러나 구조체가 매핑되는 경우 구조체의 기본 값이 반환되고 이에 따라 amount값의 기본 값이 0이므로 0이 될 수 있음
        // 따라서 if문의 조건이 0이 되는 것은 이전에 현재 게임에 베팅한 적 없는 사람이라고 판단할 수 있음
        if (bets[msg.sender].amount == 0) {
            // 베팅한 사람의 지갑 주소를 배열에 추가
            // push함수를 사용하여 배열에 값을 추가
            betters.push(msg.sender);
        } 
        // 이전에 베팅한 이력이 있는 경우
        else {
            // 이전에 베팅한 개와 다른 개에 베팅하는 경우
            // 이 게임은 한 사람은 한 개에만 베팅되어야 하므로 중복으로 베팅하는데, 다른 개에 베팅한 경우는 이전에 베팅한 금액을 반환하고 새로운 베팅 기록을 남기도록 처리
            // 각 개이름을 keccack256 해시 함수를 사용하여 문자열 비교 후 새로운 베팅에 개 이름이 다르다면 조건 충족
            if (keccak256(bytes(bets[msg.sender].dogName)) != keccak256(bytes(dogName))) {
                // 이전에 베팅한 금액 반환, payable 수식어를 사용하여 이더 송수신을 구현
                // transfer함수를 사용하여 해당 게임 참여자 지갑 주소로 이더를 반환
                // 이 경우 가스 비용이 차감 된 비용이 반환
                payable(msg.sender).transfer(bets[msg.sender].amount);
                // 총 베팅 금액에서 이전 베팅 금액을 차감
                totalBetAmount -= bets[msg.sender].amount;
                // 베팅 금액 반환 이벤트 추가 필요
            }
            // 이전에 베팅과 동일하게 똑같은 개에 베팅했다면 조건 충족
            // 이 경우 이전에 베팅했던 기록이 남은 구조체에 금액이 합산되어 기록 및 totalBetAmount 값 합산
            else{
                // 기존 금액에 새로운 베팅 금액을 합산
                // 게임 참가자의 주소를 통해 매핑 값 Bet 구조체를 가져와 amount값에 이번 베팅 비용을 가산
                bets[msg.sender].amount += msg.value;
                // 전체 베팅 금액에 추가
                totalBetAmount += msg.value;

                // BetPlaced event 발생, emit 키워드를 사용하여 event 발생
                emit BetPlaced(msg.sender, msg.value, dogName);
                // 함수 종료, 이후 로직과 겹치지 않도록 하기 위함
                return;
            }
        }

        // 베팅 정보를 저장, 이전에 베팅했다면 새로운 기록으로 덮어씌어짐
        bets[msg.sender] = Bet({amount: msg.value, dogName: dogName});
        // 전체 베팅 금액에 추가
        totalBetAmount += msg.value;

        // BetPlaced event 발생, emit 키워드를 사용하여 event 발생
        emit BetPlaced(msg.sender, msg.value, dogName);
    }

    // 경주를 종료하는 함수, 오직 소유자만 호출 가능
    // 해당 함수는 게임 진행에 중요한 함수이므로 public으로 컨트랙트 외부에서 접근 가능하도록 함
    // 게임 종료는 주최자만이 가능해야 하므로 onlyOwner 모디파이어로 수식하여 조건 실현
    function endRace() public onlyOwner {
        // 오류 처리 내용, require 함수를 사용
        // 게임이 진행 중인지 확인, raceOngoing이 true일 때 게임이 진행 중이고, 진행 중인 게임이 있어야 게임 종료가 가능함
        // false일 경우 게임 진행 중이 아니므로 오류 메시지 반환
        require(raceOngoing, "Race is not ongoing");

        // memory 수식어를 통해 함수 실행 시간동안만 변수를 저장하도록 설정
        // determineWinner 함수의 반환 값을 통해 이번 게임에서 1등인 개 이름을 설정
        // 개 이름은 string형으로 자료형 통일
        string memory winningDog = determineWinner();

        // 개 이름을 통해 1등에 베팅한 사람을 결정하고, 베팅 금액을 알맞게 분배하는 함수 distributePrizes 함수를 실행
        // 함수 인자로 게임에서 1등한 개 이름인 winningDog 변수를 전달
        distributePrizes(winningDog);
        // 게임이 끝나고 베팅 금액을 분배하는 과정도 끝마쳤으므로 게임이 끝났다고 판단 가능
        // 게임 진행 중을 기록하는 변수 raceOngoing 변수를 false로 변경, 게임 종료
        raceOngoing = false;
        // 경주 ID 증가, 다음 게임은 이번 게임 ID보다 1만큼 큰 수가 될 것
        raceId++;
        // RaceEnded event 발생, emit 키워드를 사용하여 event 발생
        // 게임 종료 시 이번 게임의 id, 1등한 개 이름을 기록
        emit RaceEnded(raceId, winningDog);
    }

    // 게임에서 승리한 개를 결정하는 함수
    // interal 가시 지정자를 사용해서 외부에서 접근이 불가능하나 상속 받은 컨트랙트에서는 사용이 가능하도록 설정
    // 게임에서 1등한 개 이름을 결정하고 반환하므로 returns string으로 설정
    function determineWinner() internal returns (string memory) {
        // 승리한 개의 번호를 저장할 변수, 초기 값은 유효한 개 번호 중  1로 설정
        // 이 코드에서 개 번호는 uint8 자료형으로 통일
        uint8 winningDogNumber = 1;
        // 가장 많은 이동거리를 기록하기 위함 이를 통해 가장 빠른 개를 선별할 것
        // 초기 값은 0으로 설정
        uint256 maxDistance = 0;
        // for문으로 uint8형으로 i를 선언, 1~7번 인덱스를 순회하며 개의 속도를 계산할 것
        // 반복문을 통해 모든 개들의 속도를 계산하여 가장 빠른 개를 선별하게 됨
        for (uint8 i = 1; i <= 7; i++) {
            // 개의 거리를 계산 (속도 * 고정 거리)
            // 전체 트랙의 거리 / 속도를 계산하여 시간을 비교하는 것이 직관적이나 계산 상 최대한 많은 거리를 가도록 계산하는 것이 간단하여 이 방법을 채택
            dogs[i].distance = dogs[i].speed * FINISH_LINE;

            // 만약 이번 개가 이전 개들보다 많은 거리를 간 경우
            // maxDistance와 비교하여 조건문 제시
            if (dogs[i].distance > maxDistance) {
                // 이번 개가 최대 거리를 갔다면, 최대 거리 변수 갱신
                maxDistance = dogs[i].distance;
                // 1등인 개의 번호도 갱신 필요
                winningDogNumber = i;
            }
        }

        // for문으로 uint8형으로 i를 선언, 1~7번 인덱스를 순회하며 우승한 개 이름을 탐색
        // 반복문으로 dogNames을 순회하며 매핑을 통해 번호를 찾아 1등한 개 번호와 동일할 때까지 탐색
        for (uint8 i = 0; i < dogNames.length; i++) {
            // 1등한 개 번호를 찾았을 경우, 매핑과 dogNames 배열 사용하여 비교 연산자로 조건 제시
            if (dogNamesToNumbers[dogNames[i]] == winningDogNumber) {
                // 승리한 개 이름을 return문으로 반환
                // 이렇게 될 경우 현재 함수가 종료되며 개 이름이 반환되므로 함수 내 반복문도 종료되게 됨.
                // break문과 비슷한 역할이나 함수 마지막에는 오류시에 반환되는 문자열이 있으므로 여기서 종료하는 것이 좋음
                return dogNames[i];
            }
        }

        // 오류 시 빈 문자열 반환, 해당 return문 까지 왔다는 것은 이전에 정상적인 처리에 해당 되지 않았기 때문
        return "";
    }

    // 베팅 승리자들에게 상금을 분배하는 함수
    // interal 가시 지정자를 사용해서 외부에서 접근이 불가능하나 상속 받은 컨트랙트에서는 사용이 가능하도록 설정
    // 베팅에 참여한 모든 사람들의 돈을 합산해 계산한 금액을 베팅 승리자들에게 동등하게 분배
    function distributePrizes(string memory winningDog) internal {
        // 베팅에 승리한 사람 수를 세는 변수, 초기값은 0
        // 베팅 금액을 분배할 때 사용
        uint256 winnersCount = 0;
        // 베팅에 승리한 사람들의 총 베팅 금액을 저장할 변수, 초기값은 0
        uint256 winnersTotalBet = 0;
        // 혹시 이번 게임의 승리자가 없을 경우 합산 금액을 저장할 변수, 초기값은 0
        uint256 carryOverAmount = 0;

        // for문으로 uint256형 변수 i를 선언 후, 게임 참여자 수만큼 순회(0 ~ 게임 참여자수 - 1 구간을 순회)
        // betters배열의 길이를 length로 알아내어 for문의 조건문으로 제시
        // 승리한 사람을 탐색하기 위해 for문 사용
        for (uint256 i = 0; i < betters.length; i++) {
            // 베팅한 개 이름을 keccak256 해시 함수를 사용하여 비교
            // solidity에서는 문자열을 직접 비교하는 것을 지원하지 않기 때문에 해시 함수로 해시 값으로 변환 후 비교
            if (keccak256(bytes(bets[betters[i]].dogName)) == keccak256(bytes(winningDog))) {
                // 승리한 사람 수 증가
                winnersCount++;
                // 승리한 사람 수의 총 베팅 금액 증가
                winnersTotalBet += bets[betters[i]].amount;
            }
        }

        // 이번 게임에서 분배될 총 금액을 계산
        // 이전 게임에서 승리자가 결정되지 않은 경우 이월 금액이 totalBetAmount에 포함되어 있을 것임 
        uint256 totalPrizePool = totalBetAmount;
        // 주최자에게 돌아갈 수수료를 계산한 변수
        // 게임에서 베팅된 총 금액의 5%를 계산하여 값을 정의
        // 수수료를 통해 주최자의 운영비 혹은 게임 실행 및 종료 시에 사용되는 가스 비용을 충당할 수 있음
        uint256 ownerFee = totalPrizePool * 5 / 100;
        // 계산된 5% 수수료를 주최자의 지갑으로 전송
        payable(owner).transfer(ownerFee);

        // 수수료 5%를 제외한 남은 상금을 계산
        // 수수료를 정의한 ownerFee를 전체 베팅 금액에서 제외하면서 계산
        uint256 remainingPrizePool = totalPrizePool - ownerFee;

        // 이번 게임의 승리자가 한 명도 없는 경우
        // 아무도 승리하지 못한 경우
        if (winnersCount == 0) {
            // 승리자가 없을 경우 금액을 이월, carryOverAmount에 값을 더함
            carryOverAmount += remainingPrizePool;
        } 
        // 이번 게임의 승리자가 있는 경우
        else {
            // for문으로 uint256형 변수 i를 선언 후, 게임 참여자 수만큼 순회(0 ~ 게임 참여자수 - 1 구간을 순회)
            // 게임 참여자를 순회하며 이번 게임 베팅에 승리한 사람들을 찾아 베팅금 반환
            for (uint256 i = 0; i < betters.length; i++) {
                // 1등한 개를 선택했는지 검사, keccak256 해시 함수를 사용하여 개 이름을 비교
                if (keccak256(bytes(bets[betters[i]].dogName)) == keccak256(bytes(winningDog))) {
                    // 맞다면 remainingPrizePool에 전체 승리한 사람들의 베팅 금액에서 사용자가 배팅한 금액의 비율을 계산하여 곱한 값을 반환 금액으로 설정
                    // 즉 승리한 사용자들 중 많이 베팅한 금액이라면 더 많은 비율을 가져갈 수 있게 되는 것
                    // 많이 걸면 많은 돈을 가져가는 구조로 사용자로 하여금 더 많은 돈을 걸 수 있게 하며 게임을 더욱 활성화할 수 있음
                    uint256 prize = remainingPrizePool * bets[betters[i]].amount / winnersTotalBet;

                    // 계산된 베팅 반환금을 해당 사용자의 지갑 주소로 전송
                    payable(betters[i]).transfer(prize);
                }
            }

            // 상금이 분배되었으므로 이월 금액을 0으로 초기화
            carryOverAmount = 0;
        }

        // for문으로 uint256형 변수 i를 선언 후, 게임 참여자 수만큼 순회(0 ~ 게임 참여자수 - 1 구간을 순회)
        // 다음 경주를 위해 데이터 초기화, betters를 순회하여 매핑을 통해 이번 게임의 베팅 정보를 모두 삭제
        for (uint256 i = 0; i < betters.length; i++) {
            // 베팅 정보 삭제, delete 키워드를 사용하여 정보 초기화
            delete bets[betters[i]];
        }
        // 베터 배열 초기화, delete 키워드를 사용하여 배열 정보 전부 삭제
        delete betters;
        // 전체 베팅 금액 초기화
        // 이월 금액이 없다면 carryOverAmount가 0이 되므로 0으로 초기화 될 것이고, 이월 금액이 있다면 해당 변수가 다음 게임의 totalBetAmount의 초기 값이 될 것
        totalBetAmount = carryOverAmount;
    }
}