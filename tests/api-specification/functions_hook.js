var hooks = require('hooks');

hooks.before('GET /api/functions/{fx} -> 200', function(test, done) {
  test.request.path = test.request.path.replace(/{fx}/, 'biologicalProcess');
  return done();
});
