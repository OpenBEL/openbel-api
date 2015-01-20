var hooks = require('hooks');

hooks.before('GET /api/expressions/{bel}/completions -> 200', function(test, done) {
  test.request.path = test.request.path.replace(/{bel}/, 'p(HGN');
  console.log('before-hook-GET-expressions');
  return done();
});
