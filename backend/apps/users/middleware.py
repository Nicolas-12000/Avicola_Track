import threading

_thread_locals = threading.local()

class CurrentUserMiddleware:
    """Middleware that saves the current request and user in thread-local storage.

    Use `get_current_user()` in signals to access the actor performing the request.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        try:
            _thread_locals.request = request
            _thread_locals.user = getattr(request, 'user', None)
            response = self.get_response(request)
            return response
        finally:
            # Clean up to avoid leaking between requests
            try:
                del _thread_locals.request
            except Exception:
                pass
            try:
                del _thread_locals.user
            except Exception:
                pass


def get_current_user():
    return getattr(_thread_locals, 'user', None)
