from tortoise import fields, models

class Manager(models.Model):
    id = fields.IntField(pk=True)
    manager = fields.CharField(max_length=20)
    password = fields.CharField(max_length=20)
    create_time = fields.DatetimeField(auto_now_add=True)
    score = fields.FloatField(default=0.0)
    is_admin = fields.BooleanField(default=False)

    class Meta:
        table = "manager"