//json-server 모듈을 가져옵니다. JSON 파일을 기반으로
//REST API를 쉽게 생성할 수 있게 해주는 라이브러리이다.
const jsonServer = require("json-server");
//json-server 애플리케이션 인스턴스 객체를 생성한다.
const server = jsonServer.create();
//'./db.json' 파일을 데이터베이스로 사용하는 라우터를 생성한다.
//이 파일의 JSON 데이터가 API의 엔드포인트 URL이 된다.
const router = jsonServer.router("./db.json");
//json-server의 기본 미들웨어들을 가져온다.
//여기에는 로깅, 정적 파일 제공, CORS 설정 등이 포함될 수 있다.
const middlewares = jsonServer.defaults();
//생성한 미들웨어들을 서버 애플리케이션에 적용한다.
server.use(middlewares);
//생성한 라우터를 서버 애플리케이션에 적용한다.
//이를 통해 '/todolist' 등 db.json에 정의된 리소스에 접근할 수 있게 된다.
server.use(router);
//서버를 8888번 포트에서 실행한다.
server.listen(8888, () => {
    //서버가 성공적으로 실행되면 콘솔에 메시지를 출력한다.
    console.log("JSON Server is running");
});