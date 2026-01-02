"""
NetBox Extra Configuration
This file contains additional configuration options that can't be configured
directly through environment variables.

All environment-based configuration is handled automatically by the netbox-docker
image. Use this file only for advanced Python-based configuration.
"""

# Specify one or more name and email address tuples representing NetBox administrators.
# These people will be notified of application errors (assuming correct email settings are provided).
# ADMINS = [
#     ['Admin Name', 'admin@example.com'],
# ]

# URL schemes that are allowed within links in NetBox
# ALLOWED_URL_SCHEMES = (
#     'file', 'ftp', 'ftps', 'http', 'https', 'irc', 'mailto', 'sftp', 'ssh', 'tel', 'telnet', 'tftp', 'vnc', 'xmpp',
# )

# Remote authentication default permissions
# REMOTE_AUTH_DEFAULT_PERMISSIONS = {}

# Custom storage backend (e.g., S3)
# STORAGE_BACKEND = 'storages.backends.s3boto3.S3Boto3Storage'
# STORAGE_CONFIG = {
#     'AWS_ACCESS_KEY_ID': 'your-key-id',
#     'AWS_SECRET_ACCESS_KEY': 'your-secret',
#     'AWS_STORAGE_BUCKET_NAME': 'netbox-media',
#     'AWS_S3_REGION_NAME': 'us-east-1',
# }

# Custom banner example
# from datetime import datetime
# BANNER_TOP = '<div class="alert alert-info">Welcome to NetBox!</div>'

# Queue configurations for background tasks
# RQ_QUEUES = {
#     'high': {
#         'USE_REDIS_CACHE': False,
#     },
#     'default': {
#         'USE_REDIS_CACHE': False,
#     },
#     'low': {
#         'USE_REDIS_CACHE': False,
#     },
# }
